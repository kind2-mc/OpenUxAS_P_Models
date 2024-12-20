
/*
  Copyright (c) 2024 by the Board of Trustees of the University of Iowa

  Licensed under the Apache License, Version 2.0 (the "License"); you
  may not use this file except in compliance with the License.  You
  may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
  implied. See the License for the specific language governing
  permissions and limitations under the License.
*/

/*
  @author Ethan Rooke
*/

// The RouteAggregatorService fills two primary roles:
//    1) it acts as a helper service to make route requests for large numbers of
//    heterogenous vehicles
//    2) it constructs the task-to-task route-cost table that is used by the
//    assignment service to order the tasks as efficiently as possible.
// Each functional role acts independently and can be modeled as two different
// state machines.


machine RouteAggregator_Aggregator {
    // Models the RouteAggregatorService's Aggregator role
    var bus: Bus;

    start state Init {
        entry (b: Bus) {
            bus = b;
            send bus, eSubscribe, this;
            goto Idle;
        }
    }

    state Idle {
        // TODO this is technically an over-simplification for the time being.
        // The each RouteRequest has its own pending states, that is the system
        // has to be able to field multiple RouteRequests simultaneously. We do
        // not currently model talking to other route providers so this is a
        // non-issue for now.

        on eMessage do ( in_msg : tMessage ) {
            if ( in_msg.kind == RouteRequest ){
                // Make a series of RoutePlanRequests to individual planners
                goto Pending, in_msg.payload as tRouteRequestMsg;
            }
            else if ( in_msg.kind == EntityConfig ) {
                // No state change
                // TODO
                // Save the vehicle information so that RoutePlanRequests can
                // be made to the appropriate planners
            }
        }
    }

    state Pending {
        entry (req: tRouteRequestMsg) {
            var resp: tRouteResponseMsg;
            resp = (req_id=req.id,);
            send bus, eMessage, (kind=RouteResponse, sender=this, payload=resp);
            goto Idle;
        }
        on eMessage do ( in_msg : tMessage ) {
            if ( in_msg.kind == RoutePlanResponse ) {
                // TODO once we have multiple route providers modelled we will
                // need to handle this case
                // Save this response, if it is the final needed response emit
                // RouteResponse and goto idle
            }
        }
    }

}

machine RouteAggregator_Collector {
    // Models the RouteAggregatorService's Collector role
    var bus: Bus;
    var next_id: tId;

    start state Init {
        entry (b: Bus) {
            next_id = 0;
            bus = b;
            send bus, eSubscribe, this;
            goto Idle;
        }
    }

    fun handleEntityState(msg: tEntityStateMsg) {
        // TODO
        // Store for use in requesting routes from vehicle positions to
        // task start locations.
    }

    state Idle {
        on eMessage do ( in_msg: tMessage ) {
            if ( in_msg.kind == UniqueAutomationRequest ) {
                // TODO
                // initialize checklist of tasks we are waiting on
                goto OptionsWait;
            } else if ( in_msg.kind == EntityState ) {
                handleEntityState(in_msg.payload as tEntityStateMsg);
            }
        }
    }

    state OptionsWait {
        // Create checklist of expected task options once all expected
        // TaskPlanOptions have been received the Collector will use the
        // current locations of the vehicles to request paths from each vehicle
        // to each task option and from each task option to every other task
        // option. Store task options and check to see if this message
        // completes the checklist. If the checklist is complete, create a
        // series of RoutePlanRequest messages to find routes from the current
        // locations of vehicles to each task and from each task to every other
        // task. Emit this series of RoutePlanRequest messages
        // OptionsWait -> RoutePending
        on eMessage do ( in_msg: tMessage ) {
            if ( in_msg.kind == TaskPlanOptions ) {
                // TODO check if all TaskPlanOptions have been received
                // TODO emit RoutePlanRequests
                goto RoutePending;
            } else if ( in_msg.kind == EntityState ) {
                handleEntityState(in_msg.payload as tEntityStateMsg);
            }
        }
    }

    fun sendMatrix() {
        var msg: tMessage;
        var payload: tAssignmentCostMatrix;
        // TODO model some actual data in here
        payload = ( id = next_id, );
        next_id = next_id + 1;
        msg = (
            kind = AssignmentCostMatrix,
            sender = this,
            payload = payload
        );
        send bus, eMessage, msg;
    }

    state RoutePending {
        on eMessage do ( in_msg: tMessage ) {
            if ( in_msg.kind == RoutePlanResponse ) {
                // TODO check if this completes the cost matrix
                sendMatrix();
                goto Idle;
            } else if ( in_msg.kind == EntityState ) {
                handleEntityState(in_msg.payload as tEntityStateMsg);
            }
        }
    }
}

