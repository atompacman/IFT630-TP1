import edu.ucdavis.jr.JR;

public final _monitor MonitorPhilosophers {

    public static class Adapter extends AbstractPhilosophers {

        // Monitor object (must be separate because _monitors cannot use heritage and cannot be nested)
        private final MonitorPhilosophers monitor;

        // Constructor
        public Adapter() {
            this.monitor = new MonitorPhilosophers(this, "Monitor");
        }
        
        // Called when a philosopher process starts
        @Override
        protected void initPhilosopherProcess(int id) {
        
        }
    
        // Called when a philosopher wants to start eating
        @Override
        protected void pickUpForks(int id) {
            monitor.pickUpForks(id);
        }
        
        // Called when a philosopher wants to stop eating
        @Override
        protected void putDownForks(int id) {
            monitor.putDownForks(id);
        }
    }
    
    // Conditional variables
    final _condvar canEat[5];
    
    // Adapter
    private Adapter adapter;
    
    // Constructor
    private MonitorPhilosophers(Adapter adapter, String id) {
        this(id);
        this.adapter = adapter;
    }
    
    // Called when a philosopher wants to start eating
    _proc void pickUpForks(int id) {
        adapter.setState(id, Adapter.HUNGRY);
        eatIfPossible(id);
        if (adapter.states[id] != Adapter.EATING) {
            _wait(canEat[id]);
        }
    }
    
    // Called when a philosopher wants to stop eating
    _proc void putDownForks(int id) {
        adapter.setState(id, Adapter.THINKING);
        eatIfPossible((id + 4) % 5);
        eatIfPossible((id + 1) % 5);
    }
    
    // Called to make a philosopher eat if possible
    private void eatIfPossible(int id) {       
        // Check if neighbours are not eating (forks are free) and that current philosopher is actually hungry
        if (adapter.states[(id + 1) % 5] != Adapter.EATING && 
            adapter.states[(id + 4) % 5] != Adapter.EATING && 
            adapter.states[id] == Adapter.HUNGRY) {
            adapter.setState(id, Adapter.EATING);
            _signal(canEat[id]);
        }
    }
    
    // Program entry point
    public static void main(String[] args) {
        registerUnexpectedEndAction();
        new Adapter();
    }
}
