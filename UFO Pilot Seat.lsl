// UFO Pilot seat
// sets pilot position and pose
// sets pilot's eye point
// under direction from UFO Menu

integer OPTION_DEBUG = FALSE;

key pilot;
integer pilotPermissions;
list viewNames;
list cameraFocusOffsets;
list cameraDistances;
list cameraPitches;
string pilotView;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Pilot Seat: "+message);
    }
}

stop_anims(key agent)
{
    list l = llGetAnimationList(agent);
    integer lsize = llGetListLength(l);
    integer i;
    for (i = 0; i <lsize; i++)
    {
        llStopAnimation(llList2Key(l, i));
    }
}

setPilotView(string viewName) {
    sayDebug("setPilotView("+viewName+")");
    integer viewIndex = llListFindList(viewNames, [viewName]);
    vector cameraFocusOffset = llList2Vector(cameraFocusOffsets, viewIndex);
    float cameraDistance = llList2Float(cameraDistances, viewIndex);
    float cameraPitch = llList2Float(cameraPitches, viewIndex);

    // https://wiki.secondlife.com/wiki/LlSetCameraParams
    // https://wiki.secondlife.com/wiki/FollowCam
    if(pilotPermissions & PERMISSION_CONTROL_CAMERA) {
        llClearCameraParams(); 
        llSetCameraParams([
        CAMERA_ACTIVE, TRUE, // 1 is active, 0 is inactive
        CAMERA_DISTANCE, cameraDistance,
        CAMERA_PITCH, cameraPitch, //(-45 to 80) degrees
        CAMERA_FOCUS_OFFSET, cameraFocusOffset, // position of the cameas
        CAMERA_POSITION_LAG, 0.1, //(0 to 3) seconds
        CAMERA_FOCUS_LAG, 0.1 , //(0 to 3) seconds
        CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
        CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
        CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
        CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
        CAMERA_POSITION_LOCKED, FALSE, //(TRUE or FALSE)
        CAMERA_FOCUS_LOCKED, FALSE //(TRUE or FALSE)
        ]);
        // CAMERA_POSITION is region relative so we don't set it
        // CAMERA_FOCUS is region relative position so we don't set it
    }
}

// ===================================================================================
default
{
    state_entry() 
    {
        sayDebug("state_entry");
        llSetSitText("Pilot");
        llSitTarget(<0.0, 0.2, -0.4> , llEuler2Rot(<0.0, -90.0, 90.0> * DEG_TO_RAD));
        pilot = llAvatarOnSitTarget();
        viewNames = ["Pilot","Third","Down"];
        cameraFocusOffsets = [<0.0, 0.0, .4>, <0.0, 0.0, 0.0>, <0.1, 0.0, -1.7>]; // where we're looking
        cameraDistances = [0, 10, 0];
        cameraPitches = [0, 10, 90];
        pilotView = "Pilot";
    }

    changed(integer change) 
    {
        sayDebug("changed("+(string)change+")");
        if (change & CHANGED_LINK) {  // Someone sat or stood up ...
            // get who sat
            pilot = llAvatarOnSitTarget();
            sayDebug("changed llAvatarOnSitTarget:"+llKey2Name(pilot));
            if (pilot) { // Sat down
                sayDebug("changed had agent; llRequestPermissions");
                llRequestPermissions(pilot, PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA);
            } else { // Stood up (or maybe crashed!)
                // Get agent to whom permissions were granted
                pilot = llGetPermissionsKey();
                if (llGetAgentSize(pilot) != ZERO_VECTOR) {  // agent is still in the sim.
                    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {    
                        // Only stop anis if permission was granted previously.
                        stop_anims(pilot);
                        llMessageLinked(LINK_ROOT, 0,"PilotIs", NULL_KEY);
                        llResetScript();
                    }
                }
            }
        }
    }    

    run_time_permissions(integer permissions) 
    {
        sayDebug("run_time_permissions("+(string)permissions+")");
        if (permissions & PERMISSION_TRIGGER_ANIMATION) {
            pilot = llGetPermissionsKey();
            if (llGetAgentSize(pilot) != ZERO_VECTOR) { // agent is still in the sim.
                // Sit the agent
                sayDebug("run_time_permissions sit");
                stop_anims(pilot);
                llStartAnimation("Sit");
                pilotPermissions = permissions; // we need this to set view
                llMessageLinked(LINK_ROOT, 1,"PilotIs", pilot);
            }
        } else {
            sayDebug("run_time_permissions did not get PERMISSION_TRIGGER_ANIMATION");
            llResetScript();
        }
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        sayDebug("link_message("+(string)msg+")");
        if (llSubStringIndex(msg, "View") == 0) {
            setPilotView(llGetSubString(msg, 4, -1));
        } else if (msg == "WhoIsPilot") {
            llMessageLinked(LINK_ROOT, 0,"PilotIs", pilot);
        }
    }
}
