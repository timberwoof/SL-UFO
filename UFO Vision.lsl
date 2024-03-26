// UFO Vision
// Sets the pilot's eyepoint

vector pilotCamera = <0.0, 0.0, 2.4>;
vector pilotLookAt = <5.0, 0.0, 2.1>;
vector thirdCamera = <-15, 0.0, 5>;
vector thirdLookAt = <2.0, 0.0, 1.3>;

updateEyepoint(string deviceName, string deviceMessage){
    list deviceParameters = llCSV2List(deviceMessage);
    vector terminalPosition =(vector)llList2String(deviceParameters,3);
    rotation cameraRotation =(rotation)llList2String(deviceParameters,4);
    vector cameraPosition = <-1.0, 0, 1.5> * cameraRotation + terminalPosition;
    vector cameraFocus =  <1.0, 0, 0.8> * cameraRotation + terminalPosition;
    // This is ONLY for implant terminals. 
        
    if(havePermissions == 1) {
        llSetCameraParams([
        CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
        CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
        CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
        CAMERA_DISTANCE, 0.0, //(0.5 to 10) meters
        CAMERA_FOCUS, cameraFocus, // region relative position
        CAMERA_FOCUS_LAG, 0.0 , //(0 to 3) seconds
        CAMERA_FOCUS_LOCKED, TRUE, //(TRUE or FALSE)
        CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
        //CAMERA_PITCH, 80.0, //(-45 to 80) degrees
        CAMERA_POSITION, cameraPosition, // region relative position
        CAMERA_POSITION_LAG, 0.0, //(0 to 3) seconds
        CAMERA_POSITION_LOCKED, TRUE, //(TRUE or FALSE)
        CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
        CAMERA_FOCUS_OFFSET, ZERO_VECTOR // <-10,-10,-10> to <10,10,10> meters
        ]);
    }
}

default
{
    state_entry()
    {
        llSay(0, "Hello, Avatar!");
    }

    touch_start(integer total_number)
    {
        llSay(0, "Touched.");
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
    }
}
