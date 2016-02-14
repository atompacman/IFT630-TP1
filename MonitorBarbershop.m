import edu.ucdavis.jr.JR;

public final _monitor MonitorBarbershop {

    public class AdapterB extends AbstractBarbershop {

        // Called when a client wants an haircut
        @Override
        protected void goToTheBarbershop(int id) {
            MonitorBarbershop.monitor.goToTheBarbershop(id);
        }
        
        // Called by the barber to wait after a client (if needed) and start the haircut
        @Override
        protected void sleepUntilClient() {
            MonitorBarbershop.monitor.sleepUntilClient();
        }
        // Called by the barber when he is done cutting the hair of its client
        @Override
        protected void waitForClientToLeave() {
            MonitorBarbershop.monitor.waitForClientToLeave();
        }
    }

    // Used by the adapter
    private static MonitorBarbershop monitor;
    
    // Used by the current client to wait for its hair to be cut
    final _condvar haircutIsFinished;
    
    // Used by the barber to wait for a client to wake himself up
    final _condvar aClientArrives;
    
    // Used by clients to wait after their turn to get an haircut
    final _condvar turnToGetAnHaircut[AdapterB.TOTAL_NUM_CLIENTS];

    // Adapter
    protected AdapterB adapter;
    
    // Constructor
    private MonitorBarbershop(String id, int placeholder) {
        this(id);
        monitor = this;
        adapter = new AdapterB();
    }

    // Called when a client wants an haircut
    _proc void goToTheBarbershop(int id) {
        adapter.log("#" + id + " arrives at the barbershop");
        
        // Return home if there are no chairs left in the waiting room
        if (adapter.waitingList.size() == AdapterB.NUM_CHAIRS_IN_WAITING_ROOM) {
            adapter.log("#" + id + " returns home because waiting room is full");
            _return;
        }
            
        // If there are not client in the shop
        if (adapter.clientCurrentlyServed == null) {
            // Be the next client
            adapter.clientCurrentlyServed = id;
            adapter.log("#" + id + " wakes up the sleeping barber and gets an haircut");

            // Wake barber up
            _signal(aClientArrives);
        } else {
            // Sit on a free chair
            int freeChair = -1;
            for (int i = 0; i < AdapterB.NUM_CHAIRS_IN_WAITING_ROOM; ++i) {
                if (adapter.chairs[i] == null) {
                    freeChair = i;
                    break;
                }
            }
            adapter.chairs[freeChair] = id;
            adapter.log("#" + id + " sits on waiting chair #" + freeChair);
            // Add itself to the waiting list
            adapter.waitingList.add(id);
        
            // Wait for the barber to call my turn
            _wait(turnToGetAnHaircut[id]);
            // Get off the chair
            adapter.chairs[freeChair] = null;
            adapter.log("#" + id + " is called by the barber, leaves waiting chair #" + freeChair + " and gets an haircut");
        }
        // Wait the the haircut to be finished
        _wait(haircutIsFinished);
    }

    // Called by the barber to wait after a client (if needed) and start the haircut
    _proc void sleepUntilClient() {
        // If there are no clients waiting for their hair to be cut, wait
        if (adapter.waitingList.isEmpty()) {
            adapter.clientCurrentlyServed = null;
            adapter.log("The barber goes to sleep because the waiting room is empty");
            _wait(aClientArrives);
        } else {
            // Get the next client in the list
            adapter.clientCurrentlyServed = adapter.waitingList.poll();
            _signal(turnToGetAnHaircut[adapter.clientCurrentlyServed]);
        }
    }
    
    // Called by the barber when he is done cutting the hair of its client
    _proc void waitForClientToLeave() {
        _signal(haircutIsFinished);
        adapter.log("The barber finished the haircut and waits for #" + adapter.clientCurrentlyServed + " to leave its shop");
    }
    
    // Program entry point
    public static void main(String[] args) {
        new MonitorBarbershop("Monitor", 0);
    }
}
