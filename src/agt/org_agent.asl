// organization agent

/* Initial beliefs and rules */
org_name("lab_monitoring_org"). // the agent beliefs that it can manage organizations with the id "lab_monitoting_org"
group_name("monitoring_team"). // the agent beliefs that it can manage groups with the id "monitoring_team"
sch_name("monitoring_scheme"). // the agent beliefs that it can manage schemes with the id "monitoring_scheme"

/* Initial goals */
!start. // the agent has the goal to start

/* 
 * Plan for reacting to the addition of the goal !start
 * Triggering event: addition of goal !start
 * Context: the agent believes that it can manage a group and a scheme in an organization
 * Body: initializes the organization
*/
@start_plan
+!start : org_name(OrgName) & group_name(GroupName) & sch_name(SchemeName) <-
  .print("Hello World");

  createWorkspace(OrgName);
  joinWorkspace(OrgName, OrgWspId);
  
  makeArtifact(OrgName, "ora4mas.nopl.OrgBoard", ["src/org/org-spec.xml"], OrgArtId)[wid(OrgWspId)];
  focus(OrgArtId)[wid(OrgWspId)];
  
  createGroup(GroupName, GroupName, GroupArtId)[artifact_id(OrgBoardArtId)];
  focus(GroupArtId)[wid(OrgWspId)];
  
  createScheme(SchemeName, SchemeName, SchemeArtId)[artifact_id(OrgBoardArtId)];
  focus(SchemeArtId)[wid(OrgWspId)];
  
  .broadcast(tell, org_workspace_available(OrgName));
  
  ?formationStatus(ok)[artifact_id(GroupArtId)];
  .print("Organization initialized successfully!").

// Plan for periodically checking if there are available roles to be filled
@check_available_roles_plan
+!check_available_roles : group_name(GroupName) & org_name(OrgName) <-
  for (role(R,_) & role_cardinality(R,Min,Max)) {
    
    .findall(A, play(A,R,_), AgentsPlayingRole);
    .length(AgentsPlayingRole, Count);
    
    // If there are not enough agents playing this role
    if (Count < Min) {
      .print("Role ", R, " needs more players (", Count, "/", Min, ")");
      .broadcast(tell, available_role(R, OrgName));
    }
  }
  .wait(15000); // Wait for 15 seconds
  !check_available_roles.  // Continue checking

// Plan if the formation status is ok.
@formation_status_is_ok_plan
+formationStatus(ok)[artifact_id(GroupArtId)] : group(GroupName,_,GroupArtId)[artifact_id(OrgName)] & scheme(SchemeName,SchemeType,SchemeArtId) <-
  .print("Group ", GroupName, " is well-formed.");
  addScheme(SchemeName)[artifact_id(GroupArtId)];
  focus(SchemeArtId).

/* 
 * Plan for reacting to the addition of the test-goal ?formationStatus(ok)
 * Triggering event: addition of goal ?formationStatus(ok)
 * Context: the agent beliefs that there exists a group G whose formation status is being tested
 * Body: if the belief formationStatus(ok)[artifact_id(G)] is not already in the agents belief base
 * the agent waits until the belief is added in the belief base
*/
@test_formation_status_is_ok_plan
+?formationStatus(ok)[artifact_id(G)] : group(GroupName,_,G)[artifact_id(OrgWsId)] <-
  .print("Waiting for group ", GroupName," to become well-formed");
  .wait(15000);
  !check_available_roles;
  .wait({+formationStatus(ok)[artifact_id(G)]}). // waits until the belief is added in the belief base

/* 
 * Plan for reacting to the addition of the goal !inspect(OrganizationalArtifactId)
 * Triggering event: addition of goal !inspect(OrganizationalArtifactId)
 * Context: true (the plan is always applicable)
 * Body: performs an action that launches a console for observing the organizational artifact 
 * identified by OrganizationalArtifactId
*/
@inspect_org_artifacts_plan
+!inspect(OrganizationalArtifactId) : true <-
  // performs an action that launches a console for observing the organizational artifact
  // the action is offered as an operation by the superclass OrgArt (https://moise.sourceforge.net/doc/api/ora4mas/nopl/OrgArt.html)
  debug(inspector_gui(on))[artifact_id(OrganizationalArtifactId)]. 

/* 
 * Plan for reacting to the addition of the belief play(Ag, Role, GroupId)
 * Triggering event: addition of belief play(Ag, Role, GroupId)
 * Context: true (the plan is always applicable)
 * Body: the agent announces that it observed that agent Ag adopted role Role in the group GroupId.
 * The belief is added when a Group Board artifact (https://moise.sourceforge.net/doc/api/ora4mas/nopl/GroupBoard.html)
 * emmits an observable event play(Ag, Role, GroupId)
*/
@play_plan
+play(Ag, Role, GroupId) : true <-
  .print("Agent ", Ag, " adopted the role ", Role, " in group ", GroupId).

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }
