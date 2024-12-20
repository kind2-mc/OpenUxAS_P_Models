
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
*/

event eComputationComplete : tId;

machine SensorManager {

    var bus: Bus;

    start state Init {
        entry (b: Bus) {
            bus = b;
            send bus, eSubscribe, this;
        }
    }

    state WaitForComputationRequest {
        on eMessage do (in_msg : tMessage) {
            var payload : tSensorComputationRequestMsg;
            if(in_msg.kind == SensorComputationRequest) {
                payload = in_msg.payload as tSensorComputationRequestMsg;
                send this, eComputationComplete, payload.id;
            }
        }

        on eComputationComplete do (req_id: tId) {
            var out_msg: tMessage;
            out_msg = (
                kind = SensorComputationResponse,
                sender = this,
                payload = (id=req_id,)
            );
            send bus, eMessage, out_msg;
        }
    }
}
