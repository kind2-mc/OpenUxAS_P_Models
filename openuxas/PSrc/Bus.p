
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

event eSubscribe : machine;

machine Bus {
    var subscribers: set[machine];

    start state WaitForEvents {
        on eSubscribe do (s: machine) {
            subscribers += (s);
        }

        on eMessage do (msg : tMessage) {
            var s: machine;
            foreach (s in subscribers) {
                if(s != msg.sender) {
                    send s, eMessage, msg;
                }
            }
        }
    }
}

