#define NUM_PHIL 4

/* Array of fork-states. */
/* If state[i] is taken, this means that the philosopher on either side of the fork has picked it up*/
byte state[NUM_PHIL];

ltl f1 {[] (state[0] == 1 || state[0] == 0)
&& (state[1] == 1 || state[1] == 0)
&& (state[2] == 1 || state[2] == 0)
&& (state[3] == 1 || state[3] == 0)};

/*
  This prototype simulates a philosofer. A philosofer has two chooses, 
  either he picks up the fork to his right or to his left, he needs both forks to eat.
  This choos is what we simulates with the dir variable.
*/

proctype phil(int id) {
  /* Deafult is that a philosopher start by picking up the fork "to the right of them", eg in place id+1 in the state array*/
  int dir = 1;

  /* Unless the it's is the first philosopher.  He then instead picks up the fork to the left of him, eg in place id+0 in the state array,
    As we need to break the symetri.
  */
  if
    ::(id == 0) ->
      dir = 0; 
    :: else -> ;
  fi

  do

    /* */
    :: atomic { (state[(id + dir) % NUM_PHIL] == 0) -> 
        state[(id + dir) % NUM_PHIL] ++;
      }

      
      if
        :: atomic {dir && (state[id] == 0) ->
            state[id] ++;
          }
          printf("eating\n");
          assert(state[id] == 1);
          assert(state[(id+1)%NUM_PHIL] == 1);
          atomic { /* This line does not have to be atomic, but is good practice*/
            state[(id) % NUM_PHIL] --;   
          }
        :: atomic {(dir == 0) && (state[id] == 0) ->
            state[id] ++;
          }
          printf("eating\n");
          assert(state[id] == 1);
          assert(state[(id+1)%NUM_PHIL] == 1);          
          atomic { /* This line does not have to be atomic, but is good practice*/
            state[(id) % NUM_PHIL] --;      
          }

        :: else -> ;
      fi

      atomic { /* This line does not have to be atomic, but is good practice*/
        state[(id + dir) % NUM_PHIL] = 0;        
      }
    ::  else -> printf("thinking\n");
  od
}



init {
  int i = 0; 

  do 
  :: i >= NUM_PHIL -> break
  :: else -> run phil(i); 
             i++ 
  od 
}
