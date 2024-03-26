// UFO Vision
// Sets the pilot's eyepoint

vector pilotCamera = <0.0, 0.0, 2.4>;
vector pilotLookAt = <5.0, 0.0, 2.1>;
vector thirdCamera = <-15, 0.0, 5>;
vector thirdLookAt = <2.0, 0.0, 1.3>;

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
