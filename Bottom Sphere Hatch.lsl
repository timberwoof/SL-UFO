integer OPTION_DEBUG = FALSE;
integer gDoorState;
integer CLOSED = 0;
integer OPEN = 1;
vector dimpleOpen = <0.14, 0.50, 0.00>;
vector dimpleClosed = <0.00, 0.50, 0.00>;
vector dimpleDelta;
integer steps = 20;
string order;
string previousOrder;

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Bottom: "+message);
    }
}

sendJSON(string jsonKey, string value, key avatarKey){
    llMessageLinked(LINK_ROOT, 0, llList2Json(JSON_OBJECT, [jsonKey, value]), avatarKey);
}

sendJSONinteger(string jsonKey, integer value, key avatarKey){
    llMessageLinked(LINK_ROOT, 0, llList2Json(JSON_OBJECT, [jsonKey, (string)value]), avatarKey);
}

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}

initialize() {
    gDoorState = OPEN;
    dimpleDelta = (dimpleOpen - dimpleClosed) / steps;
    close_door();
    open_door();
    previousOrder = "";
    }

close_door() {
    sayDebug("close");
    if (gDoorState == OPEN) {
        integer i;
        vector theDimple = dimpleOpen;
        for (i = 0; i < steps; i++) {
            theDimple = theDimple - dimpleDelta;
            llSetPrimitiveParams([PRIM_TYPE, PRIM_TYPE_SPHERE, PRIM_HOLE_CIRCLE, <0, 1, 0>, .95, <0,0,0>, theDimple]);
        }
    gDoorState = CLOSED;
    }
    sendJSONinteger("BottomIs", gDoorState, NULL_KEY);
}

open_door() {
    sayDebug("open");
    if (gDoorState == CLOSED) {
        integer i;
        vector theDimple = dimpleClosed;
        for (i = 0; i < steps; i++) {
            theDimple = theDimple + dimpleDelta;
            llSetPrimitiveParams([PRIM_TYPE, PRIM_TYPE_SPHERE, PRIM_HOLE_CIRCLE, <0, 1, 0>, .95, <0,0,0>, theDimple]);
        }
    gDoorState = OPEN;
    }
    sendJSONinteger("BottomIs", gDoorState, NULL_KEY);
}

default
{
    state_entry()
    {
        initialize();
    }
    
    link_message(integer Sender, integer Number, string msg, key Key)
    {
        sayDebug(msg);
        order = getJSONstring(msg, "Bottom", previousOrder);
        if (order != previousOrder) {
            if (order == "Open") {
                open_door();
            } else if (order == "Close") {
                close_door();
            } else if (order = "Initialize") {
                initialize();
            }
            previousOrder = order;
        }
    }
}
