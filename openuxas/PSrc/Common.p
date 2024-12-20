
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

enum tMsgKind {
    AssignmentCostMatrix,
    AutomationRequest,
    EntityConfig,
    EntityState,
    Error,
    OperatingRegion,
    RoutePlanResponse,
    RouteRequest,
    RouteResponse,
    SensorComputationRequest,
    SensorComputationResponse,
    Task,
    TaskAssignmentSummary,
    TaskInitialized,
    TaskPlanOptions,
    UniqueAutomationRequest,
    UniqueAutomationResponse
}

type tId = int;

type tMessage = (
    kind    : tMsgKind,
    sender  : machine,
    payload : data
);

type tAssignmentCostMatrix = (
    id: tId
);

type tAutomationRequestMsg = (
    entities: set[tId],
    operating_region: tId,
    tasks: set[tId]
);

type tEntityConfigMsg = (
    id: tId
);

type tEntityStateMsg = (
    id: tId,
    entity_state: data
);

type tOperatingRegionMsg = (
    id: tId
);

type tRouteRequestMsg = (
    id: tId
);

type tRouteResponseMsg = (
    req_id: tId
);

type tSensorComputationRequestMsg = (
    id: int
);

type tSensorComputationResponseMsg = (
    id: int
);

type tTaskMsg = (
    id: tId
);

type tTaskAssignmentSummary = (
    id: tId
);

type tTaskInitializedMsg = (
    id: tId
);

type tTaskPlanOptions = (
    id: tId
);

type tUniqueAutomationResponseMsg = (
    req_id: tId
);

type tUniqueAutomationRequestMsg = (
    req_id: tId,
    request: tAutomationRequestMsg
);

type tErrorMsg = (
    msg: string
);

event eMessage : tMessage;

