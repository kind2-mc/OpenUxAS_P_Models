
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

// A spec to ensure that the task properly moves through all of its states

spec TaskProgresses observes eMessage, eTaskCreated {
    // The next messages we expect to see from a machine
    var next: map[machine, tMsgKind];

    var machines: map[tId, machine];

    start state Idle {
        on eTaskCreated do ( task : machine ) {
            next[task] = TaskInitialized;
            goto Waiting;
        }

        on eMessage do ( msg : tMessage ) {
            if (msg.kind == UniqueAutomationRequest) {
                TaskRequested(
                    msg.payload as tUniqueAutomationRequestMsg
                );
                return;
            }
        }

    }

    hot state Waiting {
        on eTaskCreated do ( task : machine ) {
            next[task] = TaskInitialized;
        }

        on eMessage do ( in_msg : tMessage ) {
            var sender : machine;
            var kind : tMsgKind;

            sender = in_msg.sender;
            kind = in_msg.kind;

            if (in_msg.kind == UniqueAutomationRequest) {
                TaskRequested(
                    in_msg.payload as tUniqueAutomationRequestMsg
                );
                return;
            }

            if ( !(sender in next) ) {
                // We are not waiting to hear from this machine
                return;
            }

            if ( next[sender] != kind ){
                // This is not the state we were waiting for
                return;
            }

            // What message are we waiting for now
            if ( kind == TaskInitialized ) {
                TaskInitialized(
                    sender,
                    in_msg.payload as tTaskInitializedMsg
                );
                next -= sender;
            }
            else if ( kind == SensorComputationRequest ) {
                next[sender] = RouteRequest;
            } else {
                // No next state specified
                next -= sender;
            }

            if (sizeof(next) == 0) {
                goto Idle;
            }
        }
    }

    fun TaskInitialized(sender: machine, msg : tTaskInitializedMsg) {
        machines[msg.id] = sender;
    }

    fun TaskRequested(msg: tUniqueAutomationRequestMsg) {
        var id: tId;

        foreach ( id in msg.request.tasks )
        {
            if (!(id in machines)) {
                continue;
            }
            next[machines[id]] = SensorComputationRequest;
        }
    }
}

