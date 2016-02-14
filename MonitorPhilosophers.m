import edu.ucdavis.jr.JR;

public final _monitor MonitorPhilosophers {

    public class AdapterA extends AbstractPhilosophers {

        // Called when a philosopher wants to start eating
        @Override
        protected void pickUpForks(int id) {
            MonitorPhilosophers.monitor.pickUpForks(id);
        }
        
        // Called when a philosopher wants to stop eating
        @Override
        protected void putDownForks(int id) {
            MonitorPhilosophers.monitor.putDownForks(id);
        }
    }
    
    // Used by the adapter
    private static MonitorPhilosophers monitor;
    
    // Conditional variables
    final _condvar canEat[5];
    
    // Adapter
    private AdapterA adapter;
    
    // Constructor
    private MonitorPhilosophers(String id, int placeholder) {
        this(id);
        monitor = this;
        adapter = new AdapterA();
    }
    
    // Called when a philosopher wants to start eating
    _proc void pickUpForks(int id) {
        adapter.setState(id, AdapterA.HUNGRY);
        eatIfPossible(id);
        if (adapter.states[id] != AdapterA.EATING) {
            _wait(canEat[id]);
        }
    }
    
    // Called when a philosopher wants to stop eating
    _proc void putDownForks(int id) {
        adapter.setState(id, AdapterA.THINKING);
        eatIfPossible((id + 4) % 5);
        eatIfPossible((id + 1) % 5);
    }
    
    // Called to make a philosopher eat if possible
    private void eatIfPossible(int id) {       
        // Check if neighbours are not eating (forks are free) and that current philosopher is actually hungry
        if (adapter.states[(id + 1) % 5] != AdapterA.EATING && 
            adapter.states[(id + 4) % 5] != AdapterA.EATING && 
            adapter.states[id] == AdapterA.HUNGRY) {
            adapter.setState(id, AdapterA.EATING);
            _signal(canEat[id]);
        }
    }
    
    // Program entry point
    public static void main(String[] args) {
        new MonitorPhilosophers("Monitor", 0);
    }
}
