// sensing agent


role_goal(R, G)    :- role_mission(R, _, M) & mission_goal(M, G).
can_achieve(G)     :- .relevant_plans({+!G}, LP) & LP \== [].
i_have_plan_for(R) :- not ( role_goal(R, G) & not can_achieve(G) ).


!start.
@start_plan
+!start : true <-
    .print("Hello world").

    
// React to new organization workspace becoming available
+org_workspace_available(OrgWsp) : true <-
  .print("New organization workspace available: ", OrgWsp);
  
  // Join workspace and focus on organizational artifacts
  joinWorkspace(OrgWsp, WspId);
  lookupArtifact(OrgWsp, OrgBoard);
  focus(OrgBoard);
  
  .wait(500);
  
  // which roles are relevant for this agent
  for (role(R, _) & i_have_plan_for(R)) {
    .print("I can play the role: ", R);
    
    // Find the group board and adopt the role
    for (group(Group, _, GroupBoard)) {
      .print("Trying to adopt role ", R, " in group ", Group);
      adoptRole(R)[artifact_id(GroupBoard)];
    }
  }.

/* 
 * Plan for reacting to the addition of the goal !read_temperature
 * Triggering event: addition of goal !read_temperature
 * Context: true (the plan is always applicable)
 * Body: reads the temperature using a weather station artifact and broadcasts the reading
*/
@read_temperature_plan
+!read_temperature : true <-
	.print("I will read the temperature");
	makeArtifact("weatherStation", "tools.WeatherStation", [], WeatherStationId); // creates a weather station artifact
	focus(WeatherStationId); // focuses on the weather station artifact
	readCurrentTemperature(47.42, 9.37, Celcius); // reads the current temperature using the artifact
	.print("Temperature Reading (Celcius): ", Celcius);
	.broadcast(tell, temperature(Celcius)). // broadcasts the temperature reading

/* Import behavior of agents that work in CArtAgO environments */
{ include("$jacamoJar/templates/common-cartago.asl") }

/* Import behavior of agents that reason on MOISE organizations */
{ include("$moiseJar/asl/org-rules.asl") }

/* Import behavior of agents that work in MOISE organizations */
{ include("$jacamoJar/templates/common-moise.asl") }

/* Import behavior of agents that react to organizational events
(if observing, i.e. being focused on the appropriate organization artifacts) */
{ include("inc/skills.asl") }