
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

machine TestValidAutomationRequest {
    start state Init {
        entry {
            var b: Bus;
            var operating_region_msg: tMessage;
            var task_msg: tMessage;
            var automation_request_msg: tMessage;
            var entities: set[tId];
            var tasks: set[tId];


            operating_region_msg = (
                kind=OperatingRegion, sender=this, payload=(id=1,)
            );

            task_msg = (
                kind=Task, sender=this, payload=(id=1,)
            );

            entities += (1);
            tasks += (1);

            automation_request_msg = (
                kind=AutomationRequest,
                sender=this,
                payload=(
                    entities = entities,
                    operating_region = 1,
                    tasks = tasks
                )
            );

            b = new Bus();
            new AutomationRequestValidator(b);
            new TaskManager(b);

            setup_entity(this, b, 1);
            send b, eMessage, operating_region_msg;
            send b, eMessage, task_msg;
            send b, eMessage, automation_request_msg;
        }
    }
}

fun setup_entity(s : machine, b : Bus, id : tId) {
    var entity_config_msg: tEntityConfigMsg;
    var entity_state_msg: tEntityStateMsg;

    entity_config_msg = (id=id,);
    entity_state_msg = (id=id, entity_state=null as data);

    // The entity may or may not send an EntityConfig msg
    if ($) {
        send b, eMessage, (
            kind=EntityConfig, sender=s, payload=entity_config_msg
        );
    }

    // The entity may or may not send an EntityState msg
    if ($) {
        send b, eMessage, (
            kind=EntityState, sender=s, payload=entity_state_msg
        );
    }
}

