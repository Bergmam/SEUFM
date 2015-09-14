#define NUM_PHIL 4
byte state[NUM_PHIL];

proctype phil(int id) {
  int dir = 1; /* What direction we pick first */
  
  if
    ::(id == 0) ->
      dir = 0; /* All that is needed for breaking the symetry */
    :: else -> ;
  fi

  do
    :: atomic { (state[(id + dir) % NUM_PHIL] == 0) -> 
        state[(id + dir) % NUM_PHIL] = 1;
      }

      
      if
        :: atomic {dir && (state[id] == 0) ->
            state[id] = 1;
          }
          printf("eating\n");
          
          atomic { /* This line does not have to be atomic, but is good practice*/
            state[(id) % NUM_PHIL] = 0;            
          }
        :: atomic {(dir == 0) && (state[id] == 0) ->
            state[id] = 1;
          }
          printf("eating\n");
          
          atomic { /* This line does not have to be atomic, but is good practice*/
            state[(id) % NUM_PHIL] = 0;            
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
