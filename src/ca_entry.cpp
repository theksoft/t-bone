/*
  Refer to Glocbal Platform TEE client API specification:
  https://globalplatform.org/specs-library/tee-client-api-specification/

  Global Platform Technology
  TEE Client API Specification
  Version 1.0
  Public Release
  July 2010
  Document reference: GPD_SPE_07
*/

#include "tee_client_api.h"
#include "ca_context.hpp"
#include "ca_tee.hpp"
#include "tb_errors.hpp"
#include <cassert>
#include <iostream>

/*
  Create a "unique" 32-bit ID within the application.
  Use a truncated program address and not atruncated object memory address
  in order to limit collision.
*/
static uint32_t getMagic() {
  return (uint32_t)(uintptr_t)getMagic;
}

// __TEEC_Configure entry point
// -----------------------------------------------------------------------------

extern "C"
TEEC_Result __TEEC_Configure(const char* filename) {
  using namespace tbone::client;
  return (TeeMap::get().create(filename)) ? TEEC_SUCCESS : TEEC_ERROR_GENERIC;
}

// TEEC_InitializeContext entry point
// -----------------------------------------------------------------------------

extern "C"
TEEC_Result TEEC_InitializeContext(const char *name, TEEC_Context *context) {
  using namespace tbone::client;

  // Checking method context & arguments
  if (!context) {
    return TEEC_ERROR_BAD_PARAMETERS;
  }

  // Programmer error
  if (TeeContextMap::get().match(context)) {
    std::cerr << TEEC_ERROR_CONTEXT_REINIT << " " << std::hex << context << std::endl;
    return TEEC_ERROR_GENERIC;
  }

  // Looks for TEE name in available configured TEE
  Tee* tee = TeeMap::get().match(name);
  if (!tee) {
    return TEEC_ERROR_ITEM_NOT_FOUND;
  }

  // Add a new context
  TeeContext *c = TeeContext::create(context, name);
  if (NULL == c) {
    return TEEC_ERROR_GENERIC;
  }

  // Connect TEE
  if (!c->connect()) {
    delete c;
    return TEEC_ERROR_COMMUNICATION;
  }

  // Assign it
  context->imp.magic = getMagic();
  context->imp.data = reinterpret_cast<void*>(c);

  return TEEC_SUCCESS;
}

// TEEC_FinalizeContext entry point
// -----------------------------------------------------------------------------

extern "C"
void TEEC_FinalizeContext(TEEC_Context *context) {
  using namespace tbone::client;

  // Check parameters
  if (!context) {
    return;
  }

  // Programmer error
  if (!context->imp.data || getMagic() != context->imp.magic) {
    std::cerr << TEEC_ERROR_CONTEXT_REMOVE << " " << std::hex << context << std::endl;
    return;
  }

  // Reinterpret imp field
  TeeContext *c = NULL;
  try {
    c = static_cast<TeeContext*>(context->imp.data);
    assert(*c == context);
    if (c->hasSessions()) {
      // Programmer error
      std::cerr << TEEC_ERROR_CONTEXT_RM_SESSIONS << " " << std::hex << context << std::endl;
      return;
    }
    if (c->hasSharedMemoryBlocks()) {
      // Programmer error
      std::cerr << TEEC_ERROR_CONTEXT_RM_SHM << " " << std::hex << context << std::endl;
      return;
    }
    delete c;
  } catch(...) {
    std::cerr << TEEC_ERROR_CONTEXT_REMOVE << " " << std::hex << context << std::endl;
    return;
  }

  context->imp.magic = 0;
  context->imp.data = NULL;
}

// EOF
