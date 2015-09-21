mtype = {ok, err, msg1, msg2, msg3, keyA, keyB, agentA, agentB,
         nonceA, nonceB, agentI, keyI, nonceI };

typedef Crypt { mtype key, content1, content2, content3 };

chan network = [0] of {mtype, /* msg# */
                       mtype, /* receiver */
                       Crypt
};

/* global variables for verification*/
mtype partnerA, partnerB;
mtype statusA = err;
mtype statusB = err; 

/* Agent (A)lice */
active proctype Alice() {
  /* local variables */
  
  mtype pkey;      /* the other agent's public key                 */
  mtype pnonce;    /* nonce that we receive from the other agent   */
  Crypt messageAB; /* our encrypted message to the other party     */
  Crypt data;      /* received encrypted message                   */


  /* Initialization  */
  if
    :: true ->
      partnerA = agentB;
      pkey     = keyB;
    :: true ->
      partnerA = agentI;
      pkey = keyI;
  fi 

  /* Prepare the first message */
  
  messageAB.key = pkey;
  messageAB.content1 = agentA;
  messageAB.content2 = nonceA;  

  /* Send the first message to the other party */
  
  network ! msg1 (partnerA, messageAB);

  /* Wait for an answer. Observe the we are pattern-matching on the
     messages that start with msg2 and agentA, that is, we block until 
     we see a message with values msg2 and agentA as the first and second  
     components. The third component is copied to the variable data. */

  network ? (msg2, agentA, data);

  /* We proceed only if the key field of the data matches keyA and the
     received nonce is the one that we have sent earlier; block
     otherwise.  */

  (data.key == keyA) && (data.content1 == nonceA);

  /* Patch */

  data.content3 == partnerA;

  /* Obtain Bob's nonce */
  
  pnonce = data.content2;

  /* Prepare the last message */  
  messageAB.key = pkey;
  messageAB.content1 = pnonce; 
  messageAB.content2 = 0;  /* content2 is not used in the last message,
                              just set it to 0 */

  
  /* Send the prepared messaage */
  network ! msg3 (partnerA, messageAB);

  
  /* and last - update the auxilary status variable */
  statusA = ok;
}

active proctype Bob() {

  /* Variables */ 
  mtype pkey;      /* the other agent's public key                 */
  mtype pnonce;    /* nonce that we receive from the other agent   */
  Crypt messageBA; /* our encrypted message to the other party     */
  Crypt data;      /* received encrypted message                   */


  /* Initialization  */
  partnerB = agentA;
  pkey     = keyA;

  /* Listen to first message */
  network ? (msg1, agentB, data);
  pnonce = data.content2;

  /* Prepare second message */

  messageBA.key = pkey;
  messageBA.content1 = pnonce;
  messageBA.content2 = nonceB;
  messageBA.content3 = agentB;

  /* Send second message */
  network ! msg2 (partnerB, messageBA);

  /* Recieve third message */
  network ? (msg3, agentB, data);

  (data.content1 == nonceB && data.key == keyB);

  printf("Allt gick bra!")

   /* End */
   statusB = ok;
}

bool knows_nonceA, knows_nonceB;

active proctype Intruder() {
  mtype msg, recpt;
  Crypt data, intercepted;
  do
    :: network ? (msg, _, data) ->
       if /* perhaps store the message */
         :: (data.key == keyI) -> 
            intercepted.key   = data.key;
            intercepted.content1 = data.content1;
            intercepted.content2 = data.content2;
        
            if
              :: data.content1 == agentA ->
                knows_nonceA = true;
              :: data.content2 == agentB ->
                knows_nonceB = true;
              :: else -> ;
            fi
         :: else -> ;
       fi ;

    :: /* Replay or send a message */
       if /* choose message type */
         :: msg = msg1;
         :: msg = msg2;
         :: msg = msg3;
       fi ;
       if /* choose a recepient */
         :: recpt = agentA;
         :: recpt = agentB;
       fi ;
       if /* replay intercepted message or assemble it */
         :: data.key    = intercepted.key;
            data.content1  = intercepted.content1;
            data.content2  = intercepted.content2;
            data.content3 = intercepted.content3;
         :: if /* assemble content1 */
              :: data.content1 = agentA;
              :: data.content1 = agentB;
              :: data.content1 = agentI;
              :: data.content1 = nonceI;
            fi ;     
            if /* assemble key */
              :: data.key = keyA;
              :: data.key = keyB;
              :: data.key = keyI;
            fi ;

            if
              :: (data.content1 == agentA && knows_nonceA) ->
                data.content2 = nonceA;
                data.content3 = agentI;
              :: (data.content1 == agentB && knows_nonceB) ->
                data.content2 = nonceB;
              :: else -> data.content2 = nonceI;
            fi
       fi ;
      network ! msg (recpt, data);
  od 
}


ltl propAB {((statusA == ok) && (statusB == ok)) -> ((partnerA == agentB) && (partnerB == agentA))};
ltl propA {(statusA == ok && partnerA == agentB) -> !knows_nonceA};
ltl propB {(statusB == ok && partnerB == agentA) -> !knows_nonceB}