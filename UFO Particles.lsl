// UFO Particles
integer OPTION_DEBUG = TRUE;
string particles;
string tagret;

string sound_scan = "f5ae60d2-9f03-984a-e846-d5f499b64e17";
string sound_antigravity = "dd7a57dc-89dc-3584-3c1a-36727424bedf";

sayDebug(string message)
{
    if (OPTION_DEBUG)
    {
        llOwnerSay("UFO Particles: "+message);
    }
}

string getJSONstring(string jsonValue, string jsonKey, string valueNow){
    string result = valueNow;
    string value = llJsonGetValue(jsonValue, [jsonKey]);
    if (value != JSON_INVALID) {
        result = value;
    }
    return result;
}

scan(key target) {
    sayDebug("scan("+llKey2Name(target)+")");
    llLoopSound(sound_scan, 1.0);
llParticleSystem([
            PSYS_PART_FLAGS, PSYS_PART_EMISSIVE_MASK |
                PSYS_PART_INTERP_COLOR_MASK | 
                PSYS_PART_INTERP_SCALE_MASK | 
                PSYS_PART_FOLLOW_SRC_MASK | 
                PSYS_PART_FOLLOW_VELOCITY_MASK |
                PSYS_PART_TARGET_POS_MASK | 
                PSYS_PART_TARGET_LINEAR_MASK,
             PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY,
             PSYS_PART_START_ALPHA, 0.7,
             PSYS_PART_END_ALPHA, 0.2,
             PSYS_PART_START_COLOR, <0,0.5,1>,
             PSYS_PART_END_COLOR, <0,1,1>,
             PSYS_PART_START_SCALE, <0,0,0>,
             PSYS_PART_END_SCALE, <2,2,2>, 
             PSYS_PART_MAX_AGE,1,
             PSYS_SRC_BURST_RATE, 0.1,
             PSYS_SRC_ACCEL, <0,0,0>,
             PSYS_SRC_BURST_PART_COUNT, 4,
             PSYS_SRC_BURST_RADIUS, 0.1,
             PSYS_SRC_BURST_SPEED_MIN, 1,
             PSYS_SRC_BURST_SPEED_MAX, 1,
             PSYS_SRC_TARGET_KEY, target,
             PSYS_SRC_ANGLE_BEGIN, 1.54, 
             PSYS_SRC_ANGLE_END, 1.55,
             PSYS_SRC_OMEGA, <0,0,2>,
             PSYS_SRC_MAX_AGE, 0,
             PSYS_SRC_TEXTURE, "e5f8a843-044d-a906-225c-aa26ceffad50"
        ]); 
}

antigravity(key target) {
    sayDebug("antigravity("+llKey2Name(target)+")");
llLoopSound(sound_antigravity, 1.0);
llParticleSystem([
PSYS_PART_FLAGS, PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK | PSYS_PART_EMISSIVE_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_INTERP_COLOR_MASK,
PSYS_SRC_PATTERN, 4, 
PSYS_PART_START_ALPHA, 0.5,
PSYS_PART_END_ALPHA, 0.5,
PSYS_PART_START_COLOR, <0.0, 1.0, 0.0>,
PSYS_PART_END_COLOR, <0.5, 1.0, 0.0>,
PSYS_PART_START_SCALE, <0.5, 0.5, 0.0>,
PSYS_PART_END_SCALE, <0.5, 0.5, 0.0>,
PSYS_PART_MAX_AGE, 2.0,
PSYS_SRC_MAX_AGE, 0.0,
PSYS_SRC_ACCEL, <0.0, 0.0, -12.0>,
PSYS_SRC_ANGLE_BEGIN, 4.0,
PSYS_SRC_ANGLE_END, 5,
PSYS_SRC_BURST_PART_COUNT, 10,
PSYS_SRC_BURST_RATE, 0.1,
PSYS_SRC_BURST_RADIUS, 0.0,
PSYS_SRC_BURST_SPEED_MIN, 2.0,
PSYS_SRC_BURST_SPEED_MAX, 3.0,
PSYS_SRC_OMEGA, <0.0, 0.0, 30.0>,
PSYS_SRC_TARGET_KEY, (key)target, 
PSYS_SRC_TEXTURE, ""]);
}

lightbeam(key target) {
llParticleSystem([
PSYS_PART_FLAGS, 259,
PSYS_SRC_PATTERN, 8, 
PSYS_PART_START_ALPHA, 0.100000,
PSYS_PART_END_ALPHA, 0.100000,
PSYS_PART_START_COLOR, <1.000000, 1.000000, 0.900000>,
PSYS_PART_END_COLOR, <1.000000, 1.000000, 0.900000>,
PSYS_PART_START_SCALE, <1.000000, 4.000000, 0.00000>,
PSYS_PART_END_SCALE, <1.000000, 4.000000, 0.000000>,
PSYS_PART_MAX_AGE, 1.500000,
PSYS_SRC_MAX_AGE, 0.000000,
PSYS_SRC_ACCEL, <0.000000, 0.000000, 0.000000>,
PSYS_SRC_ANGLE_BEGIN, 3.0,
PSYS_SRC_ANGLE_END, 3.141592,
PSYS_SRC_BURST_PART_COUNT, 10,
PSYS_SRC_BURST_RATE, 0.100000,
PSYS_SRC_BURST_RADIUS, 0.000000,
PSYS_SRC_BURST_SPEED_MIN, 4.500000,
PSYS_SRC_BURST_SPEED_MAX, 4.500000,
PSYS_SRC_OMEGA, <0.000000, 0.000000, 0.000000>,
PSYS_SRC_TARGET_KEY,(key)"", 
PSYS_SRC_TEXTURE, ""]);
}

particles_off() {
    llParticleSystem([]);
    llStopSound();
}

default
{
    state_entry()
    {
        particles_off();
    }

    link_message(integer sender_num, integer num, string msg, key id) 
    {
        if (msg == "Scan") {
            scan(id);
            llSleep(3);
            particles_off();
        } else if (msg == "Antigravity") {
            antigravity(id);
        } else if (msg == "Lightbeam") {
            lightbeam(NULL_KEY);
        } else if (msg == "Particles Off"){
            particles_off();
        }
    }

}
