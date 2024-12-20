
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

machine AutomationRequestValidator {

    var bus: Bus;
    var next_id: tId;
    var timer: Timer;

    var available_entities: set[tId];
    var entity_state: map[tId, data];
    var available_tasks: set[tId];
    var available_operating_regions: set[tId];

    var pending_requests: seq[tMessage];

    start state Init {
        entry (b: Bus) {
            bus = b;
            next_id = 0;
            timer = CreateTimer(this);

            send bus, eSubscribe, this;

            goto Idle;
        }
    }

    fun HandleEntityConfigMsg(msg : tEntityConfigMsg) {
        available_entities += (msg.id);
    }

    fun HandleOperatingRegionMsg(msg : tOperatingRegionMsg) {
        available_operating_regions += (msg.id);
    }

    fun HandleTaskMsg(msg : tTaskMsg) {
        available_tasks += (msg.id);
    }

    fun HandleEntityStateMsg(msg: tEntityStateMsg) {
      entity_state[msg.id] = msg.entity_state;
    }

    fun HandleNonAutomationRequest(in_msg : tMessage) {
        if(in_msg.kind == EntityConfig) {
            HandleEntityConfigMsg(in_msg.payload as tEntityConfigMsg);
        }
        else if(in_msg.kind == OperatingRegion) {
            HandleOperatingRegionMsg(in_msg.payload as tOperatingRegionMsg);
        }
        else if(in_msg.kind == Task) {
            HandleTaskMsg(in_msg.payload as tTaskMsg);
        }
        else if(in_msg.kind == EntityState) {
            HandleEntityStateMsg(in_msg.payload as tEntityStateMsg);
        }
    }

    fun GetAutomationRequestPayload(in_msg: tMessage) : tAutomationRequestMsg {
        var payload : tAutomationRequestMsg;
        payload = in_msg.payload as tAutomationRequestMsg;
        return payload;
    }

    fun IsValidAutomationRequest(request: tAutomationRequestMsg) : bool {
        var id : tId;
        var valid : bool;

        valid = sizeof(request.entities)>0 && sizeof(request.tasks)>0;
        valid = valid && request.operating_region in available_operating_regions;
        foreach (id in request.entities) {
            // Any vehicle requested in an AutomationRequest must previously be
            // described by an associated EntityConfig
            valid = valid && id in available_entities;

            // Each vehicle in an AutomationRequest must have reported its state
            valid = valid && id in keys(entity_state);
        }

        foreach (id in request.tasks) {
            valid = valid && id in available_tasks;
        }

        return valid;
    }

    fun CreateUniqueAutomationRequestMsg(request: tAutomationRequestMsg) : tMessage {
        var msg: tMessage;
        msg = (
            kind = UniqueAutomationRequest,
            sender = this,
            payload = (req_id = next_id, request = request)
        );
        next_id = next_id + 1;
        return msg;
    }

    fun SendUniqueAutomationRequest(out_msg: tMessage) {
        send bus, eMessage, out_msg;
        StartTimer(timer);
    }

    fun RemoveFrontAndSendNext() {
        pending_requests -= (0);
        if (sizeof(pending_requests)==0) {
            goto Idle;
        }
        else {
            SendUniqueAutomationRequest(pending_requests[0]);
        }
    }

    fun CheckResponseId(response_id: tId) {
        var request: tUniqueAutomationRequestMsg;
        request = pending_requests[0].payload as tUniqueAutomationRequestMsg;

        assert request.req_id == response_id,
            format ("Id of fulfilled request ({0}) does not match id of pending request ({1})",
                response_id, request.req_id
            );
    }

    fun HandleUniqueAutomationResponse(in_msg: tMessage) {
        var payload: tUniqueAutomationResponseMsg;

        payload = in_msg.payload as tUniqueAutomationResponseMsg;

        assert sizeof(pending_requests)>0,
            "Expected pending_requests queue to be non-empty";

        CheckResponseId(payload.req_id);

        RemoveFrontAndSendNext();
    }

    fun SendErrorMessage(msg: string) {
        var out_msg: tMessage;
        out_msg = (
            kind = Error,
            sender = this,
            payload = (msg = msg,)
        );
        send bus, eMessage, out_msg;
    }

    state Idle {
        on eMessage do (in_msg : tMessage) {
            var request: tAutomationRequestMsg;
            var out_msg: tMessage;
            HandleNonAutomationRequest(in_msg);
            if(in_msg.kind == AutomationRequest) {
                request = GetAutomationRequestPayload(in_msg);
                if(IsValidAutomationRequest(request)) {
                    out_msg = CreateUniqueAutomationRequestMsg(request);
                    pending_requests += (sizeof(pending_requests), out_msg);
                    SendUniqueAutomationRequest(out_msg);
                    goto Busy;
                }
                else {
                    SendErrorMessage("Invalid Automation Request");
                }
            }
            else if(in_msg.kind == UniqueAutomationResponse) {
                // Publish same message?
                CancelTimer(timer);
            }
        }
        ignore eTimeOut;
    }

    state Busy {
        on eMessage do (in_msg: tMessage) {
            var request: tAutomationRequestMsg;
            var out_msg: tMessage;
            HandleNonAutomationRequest(in_msg);
            if(in_msg.kind == AutomationRequest) {
                request = GetAutomationRequestPayload(in_msg);
                if(IsValidAutomationRequest(request)) {
                    out_msg = CreateUniqueAutomationRequestMsg(request);
                    pending_requests += (sizeof(pending_requests), out_msg);
                }
                else {
                    SendErrorMessage("Invalid Automation Request");
                }
            }
            else if(in_msg.kind == UniqueAutomationResponse) {
                // Publish same message?
                CancelTimer(timer);
                HandleUniqueAutomationResponse(in_msg);
            }
        }

        on eTimeOut do {
            // Assume an error has ocurred
            assert sizeof(pending_requests)>0,
                "Expected pending_requests queue to be non-empty";

            RemoveFrontAndSendNext();
        }
    }

}

