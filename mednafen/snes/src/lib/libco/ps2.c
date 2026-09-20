#define LIBCO_C
#include "libco.h"

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <kernel.h>

/* Since cothread_t is a void pointer it must contain an address. We can't return a reference to a local variable
 * because it would go out of scope, so we create a static variable instead so we can return a reference to it.
 */
static int32_t active_thread_id = -1;
extern void *_gp;

cothread_t co_active()
{
  active_thread_id = GetThreadId();
  return &active_thread_id;
}

cothread_t co_create(unsigned int size, void (*entrypoint)(void))
{
  /* Similar scenario as with active_thread_id except there will only be one active_thread_id while there could be many
   * new threads each with their own handle, so we create them on the heap instead and delete them manually when they're
   * no longer needed in co_delete().
   */
  cothread_t handle = malloc(sizeof(uint32_t));
  if (!handle)
      return NULL;

  void *threadStack = (void *)malloc(size);
  if (threadStack == NULL)
  {
      printf("libco: ERROR: creating threadStack\n");
      free(handle);
      return NULL;
  }

  ee_thread_t thread;
  thread.stack_size         = size;
  thread.gp_reg             = &_gp;
  thread.func               = (void *)entrypoint;
  thread.stack              = threadStack;
  thread.option             = 0;
  thread.initial_priority   = 1;

  int32_t new_thread_id = CreateThread(&thread);
  if (new_thread_id < 0)
  {
      printf("libco: ERROR: creating thread\n");
      free(threadStack);
      free(handle);
      return NULL;
  }

  StartThread(new_thread_id, NULL);
  *(uint32_t *)handle = new_thread_id;
  return handle;
}

void co_delete(cothread_t handle)
{
  if (!handle)
      return;
      
  TerminateThread(*(uint32_t *)handle);
  DeleteThread(*(uint32_t *)handle);
  free(handle);
}

void co_switch(cothread_t handle)
{
  WakeupThread(*(uint32_t *)handle);
  /* Sleep the currently active thread so the new thread can start */
  SleepThread();
}