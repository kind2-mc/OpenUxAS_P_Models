
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

machine AssignmentTreeBranchBound {
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

    state Idle {
        on eMessage do ( in_msg : tMessage ) {
            if ( in_msg.kind == UniqueAutomationRequest ) {
                // TODO store requestID for identification of corresponding
                // TaskPlanOptions and CostMatrix
                goto Wait;
            }
        }
    }

    fun sendTaskAssignmentSummary() {
        var msg: tMessage;
        var payload: tTaskAssignmentSummary;
        payload = ( id = next_id, );
        next_id = next_id + 1;
        msg = (
            kind = TaskAssignmentSummary,
            sender = this,
            payload = payload
        );
        send bus, eMessage, msg;
    }

    state Wait {
        on eMessage do ( in_msg : tMessage )  {
            if ( in_msg.kind == TaskPlanOptions ) {
                // No state change
                // Store cost of each task option for look-up during
                // optimization.
            } else if ( in_msg.kind == AssignmentCostMatrix ) {
                // TODO emulate optimization
                sendTaskAssignmentSummary();
            }
        }
    }
}

