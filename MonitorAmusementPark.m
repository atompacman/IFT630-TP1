import edu.ucdavis.jr.JR;
import edu.ucdavis.jr.QuiescenceRegistrationException;

import java.util.ArrayList;

import java.util.concurrent.ThreadLocalRandom;

/*
 * Alexandre Blouin
 * Jérémie Coulombe
 */

public _monitor MonitorAmusementPark {

    // Lap duration in seconds (5 laps = 1 ride)
    private static final int LAP_DURATION_SECONDS = 2;

    // Program duration in seconds
    private static final int PROGRAM_DURATION_SECONDS = 35;

    // Maximum time in milliseconds that is randomly added to base time when riding the rollecoaster
    private static final int RANDOM_ADDITIONNAL_TIME_MILLIS = 5;

    // Rollercoaster maximum capacity
    private static final int C = 10;

    // Total number of people in line and on the rollercoaster
    private static final int N = 50;

    // Array containing the IDs of the people in the rollercoaster car (empty at first)
    private static ArrayList<Integer> car = new ArrayList<Integer>(C);

    // Conditional variable used by the rollercoaster to know when it can start (when the car is full)
    _condvar canStart;

    // Conditional variable used by a person to know if it can enter in the car (when the car is empty). 
    // It starts at 1 because we want the first one to be able to enter directly. 
    _condvar canEnter;

    // Conditional variable used by a person to know if it an exit the car (when the ride has stopped)
    _condvar canExit;

    _var boolean entering = true;

    _var boolean exiting = false;



    // Monitor
    private static MonitorAmusementPark monitor = new MonitorAmusementPark("Monitor");

    // Rollercoaster process
    private static process RollerCoaster {
        // It goes on and on
        while (true) {
            // System.out.println("5 laps and stop");
            monitor.do5LapsAndStop();
        }
    }

    // Person process
    private static process Person((int id = 0; id < N; ++id)) {
        // Those guys never stop !
        
        while (true) {
            monitor.getInCarIfPossible(id);
            monitor.getOutOfCarIfPossible(id);
        }
    }

    _proc void getInCarIfPossible(int id) {
        if (!monitor.entering)
            _wait(canEnter);
        else
            car.add(id);

        System.out.println("Person #" + id + " got in the car. Size = " + car.size());
        if (car.size() == C) {
            System.out.println("Car is now full. The ride is about to begin!");
            monitor.entering = false;
            monitor.exiting = false;
            _signal(canStart);
        }
        
    }

    _proc void getOutOfCarIfPossible(int id) {
        if (!monitor.exiting)
            _wait(canExit);
        else
            car.remove(new Integer(id));

        System.out.println("Person #" + id + " got out of the car. Size = " + car.size());
        if (car.size() == 0) {
            System.out.println("Car is now empty. People will now be able to get in.");
            monitor.exiting = false;
            monitor.entering = true;
            _signal(canEnter);
        }
    }

    _proc void do5LapsAndStop() {
        _wait(canStart);
        System.out.println("Ride is starting! WOOOO!!");
        wait(5 * LAP_DURATION_SECONDS * 1000);
        System.out.println("Ride has stopped.");
        System.out.println("Everyone is getting out of the car (and back in line for more).");
        monitor.exiting = true;
        _signal(canExit);
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
            System.err.println("WAITING INTERRUPTED !");
            JR.exit(1);
        }
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
