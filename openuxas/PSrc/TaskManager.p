
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

event eTaskCreated : machine;

machine TaskManager {

    var bus: Bus;

    start state Init {
        entry (b: Bus) {
            bus = b;
            send bus, eSubscribe, this;
            goto WaitForTaskMsg;
        }
    }


    fun HandleTaskMsg(msg: tTaskMsg) {
        var task: machine;
        task = new Task((bus=bus, id = msg.id));
        announce eTaskCreated, task;
    }

    state WaitForTaskMsg {
        on eMessage do (in_msg : tMessage) {
            var payload : tTaskMsg;
            if(in_msg.kind == Task) {
                HandleTaskMsg(in_msg.payload as tTaskMsg);
            }
        }
    }

}

