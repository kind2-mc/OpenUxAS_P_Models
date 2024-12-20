
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
  @author Daniel Larraz
  @author Ethan Rooke
*/

event eInitializedTask;

machine Task {

    var bus: Bus;
    var id: tId;

    var next_request_id: tId;

    start state Init {
        entry (inputs:(bus: Bus, id: tId)) {
            var out_msg: tMessage;
            bus = inputs.bus;
            id = inputs.id;
            next_request_id = 0;
            send bus, eSubscribe, this;

            out_msg = (
                kind    = TaskInitialized,
                sender  = this,
                payload = (id=id,)
            );

            send bus, eMessage, out_msg;
            goto Idle;
        }
    }

    state Idle {
        on eMessage do (in_msg : tMessage) {
            var payload : tUniqueAutomationRequestMsg;
            if(in_msg.kind == UniqueAutomationRequest) {
                payload = in_msg.payload as tUniqueAutomationRequestMsg;
                if(id in payload.request.tasks) {
                    goto SensorRequest;
                }
            }
        }
    }

    state SensorRequest {
        entry {
            var out_msg: tMessage;
            out_msg = (
                kind = SensorComputationRequest,
                sender = this,
                payload = (id=next_request_id,)
            );
            next_request_id = next_request_id + 1;
            send bus, eMessage, out_msg;
        }

        on eMessage do (in_msg : tMessage) {
            var payload : tSensorComputationResponseMsg;
            if(in_msg.kind == SensorComputationResponse) {
                payload = in_msg.payload as tSensorComputationResponseMsg;
                if(payload.id == next_request_id - 1) {
                    send bus, eMessage, (
                        kind=RouteRequest,
                        sender=this,
                        payload=(id=next_request_id,)
                    );
                    next_request_id = next_request_id + 1;
                    goto OptionRoutes;
                }
            }
        }
    }

    fun SendTaskPlanOptionsMessage() {
        var msg: tMessage;
        var payload: tTaskPlanOptions;
        payload = (
            id = next_request_id,
        );
        next_request_id = next_request_id + 1;
        msg = (
            kind = TaskPlanOptions,
            sender = this,
            payload = payload
        );
        send bus, eMessage, msg;
    }

    state OptionRoutes {
        // After the SensorManagerService has replied with the appropriate sensor
        // calculations, the Task can request waypoints from the
        // RouteAggregatorService that carry out the on-Task goals. For example, an
        // AreaSearchTask can request routes from key surveillance positions that
        // ensure sensor coverage of the entire area. The Task remains in the
        // OptionRoutes state until the RouteAggregatorService replies

        // When this process is done we publish a TaskOptions message then
        // transition to OptionsPublished state
        on eMessage do (in_msg : tMessage) {
            var payload : tRouteResponseMsg;
            if (in_msg.kind == RouteResponse ) {
                payload = in_msg.payload as tRouteResponseMsg;
                if (payload.req_id == next_request_id - 1) {
                    SendTaskPlanOptionsMessage();
                    goto OptionsPublished;
                }
            }
        }
    }

    state OptionsPublished {}
}

