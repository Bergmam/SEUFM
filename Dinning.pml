#define NUM_PHIL 4
byte state[NUM_PHIL];

proctype phil(int id) {
  do 
    :: (state[id % NUM_PHIL] == 0) -> 
      atomic {
        state[id] = 1;
      }
      printf("eating\n");
      atomic {
        state[id] = 0;
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
