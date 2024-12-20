
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

// Any vehicle requested in an AutomationRequest must previously be
// described by an associated EntityConfig

spec RequestedVehiclesExist observes eMessage {
    var available_entities: set[tId];

    fun HandleEntityConfigMsg(msg : tEntityConfigMsg) {
        available_entities += (msg.id);
    }

    fun HandleUniqueAutomationRequestMsg(msg : tUniqueAutomationRequestMsg) {
        var entity: tId;
        foreach (entity in msg.request.entities)
        {
            assert entity in available_entities,
            format ("Unknown entityId {0} in the automation request. Valid entityIds = {1}",
              entity, available_entities);
        }
    }

    start state Idle {
        on eMessage do (msg: tMessage) {
            if (msg.kind == EntityConfig) {
                HandleEntityConfigMsg(msg.payload as tEntityConfigMsg);
            }
            else if (msg.kind == UniqueAutomationRequest) {
                HandleUniqueAutomationRequestMsg(msg.payload as tUniqueAutomationRequestMsg);
            }
        }
    }
}

spec RequestedVehiclesDeclareState observes eMessage {
    var available_entities: set[tId];

    fun HandleEntityStateMsg(msg : tEntityStateMsg) {
        available_entities += (msg.id);
    }

    fun HandleUniqueAutomationRequestMsg(msg : tUniqueAutomationRequestMsg) {
        var entity: tId;
        foreach (entity in msg.request.entities)
        {
            assert entity in available_entities,
            format ("entityId {0} in the automation request has not declared its state. Valid entityIds = {1}",
              entity, available_entities);
        }
    }

    start state Idle {
        on eMessage do (msg: tMessage) {
            if (msg.kind == EntityState) {
                HandleEntityStateMsg(msg.payload as tEntityStateMsg);
            }
            else if (msg.kind == UniqueAutomationRequest) {
                HandleUniqueAutomationRequestMsg(msg.payload as tUniqueAutomationRequestMsg);
            }
        }
    }
}

