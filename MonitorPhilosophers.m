import edu.ucdavis.jr.JR;
import edu.ucdavis.jr.QuiescenceRegistrationException;

import java.util.concurrent.ThreadLocalRandom;

public _monitor MonitorPhilosophers {

    // Base time in milliseconds a philosopher takes to eat
    private static final int BASE_TIME_EAT_MILLIS = 800;
    
    // Base time in milliseconds a philosopher takes to think
    private static final int BASE_TIME_THINK_MILLIS = 500;
    
    // Maximum time in milliseconds that is randomly added to base time when eating/thinking
    private static final int RANDOM_ADDITIONNAL_TIME_MILLIS = 5;
    
    // Program duration in seconds
    private static final int PROGRAM_DURATION_SECONDS = 10;

    // Possible philosopher states (not enums constants to speed up debug string building)
    private static final char THINKING = 'T';
    private static final char HUNGRY   = 'H';
    private static final char EATING   = 'E';
    
    // Philosophers' state
    private static char[] states = new char[5];
    static {
        for (int i = 0; i < 5; ++i) {
            states[i] = THINKING;
        }
    }
    
    // Monitor
    private static MonitorPhilosophers monitor = new MonitorPhilosophers("Monitor");
    
    // Conditional variables
    _condvar canEat[5];
    
    // Philosopher processes
    private static process Philosopher((int id = 0; id < 5; ++id)) {
        // Those guys never stops !
        while (true) {
            monitor.pickUpForks(id);
            wait(BASE_TIME_EAT_MILLIS);
            monitor.putDownForks(id);
            wait(BASE_TIME_THINK_MILLIS);
        }
    }
    
    // Process that stops the program after a certain time
    private static process EndProgram {
        wait(PROGRAM_DURATION_SECONDS * 1000);
        JR.exit(1);
    }
    
    // Encapsulates the waiting process
    private static void wait(int baseTimeMillis) {
        try {
            // Wait for specified time plus some more milliseconds
            Thread.sleep(baseTimeMillis + ThreadLocalRandom.current().nextInt(RANDOM_ADDITIONNAL_TIME_MILLIS + 1));
        } catch (InterruptedException e) {
            System.err.println("NEVER INTERRUPT A THINKING PHILOSOPHER. NEVER. JUST DON'T. IT'S THE ONLY THING SOCRATES KNEW.");
            JR.exit(1);
        }
    }
    
    // Called when a philosopher wants to start eating
    _proc void pickUpForks(int id) {
        setState(id, HUNGRY);
        eatIfPossible(id);
        if (states[id] != EATING) {
            _wait(canEat[id]);
        }
    }
    
    // Called when a philosopher wants to stop eating
    _proc void putDownForks(int id) {
        setState(id, THINKING);
        eatIfPossible((id + 4) % 5);
        eatIfPossible((id + 1) % 5);
    }
    
    // Called to make a philosopher eat if possible
    private void eatIfPossible(int id) {       
        // Check if neighbours are not eating (forks are free) and that current philosopher is actually hungry
        if (states[(id + 1) % 5] != EATING && states[(id + 4) % 5] != EATING && states[id] == HUNGRY) {
            setState(id, EATING);
            _signal(canEat[id]);
        }
    }
    
    // Encapsulates state changing and prints debug info
    private void setState(int id, char newState) {
        states[id] = newState;
        StringBuilder sb = new StringBuilder();
        sb.append("  ").append(states[0]).append('\n');
        sb.append(states[4]).append("   ").append(states[1]).append("\n ");
        sb.append(states[3]).append(' ').append(states[2]);
        sb.append("\n-----");
        System.out.println(sb.toString());
    }
    
    // Called when the program is in trouble !
    public static op void unexpectedEnd() {
        System.err.println("PROCESSES ARE EITHER IN A DEADLOCK OR ALL DEAD!!!");
    }

    // Program entry point
    public static void main(String[] args) {
        try {
            JR.registerQuiescenceAction(unexpectedEnd);
        } catch (QuiescenceRegistrationException e) {
            e.printStackTrace();
        }
    }
}
