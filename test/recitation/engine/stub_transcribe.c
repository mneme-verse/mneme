// Minimal stub of the transcribe.cpp C API for binding tests.
//
// Implements just enough of the streaming surface for the Dart FFI
// bindings to call through: canned version/status strings, a fake
// session handle, a revision counter, and a fixed transcript. It
// validates signatures and struct layout, not recognition behavior.
#include <stddef.h>
#include <stdint.h>
#include <string.h>

typedef struct {
  uint64_t struct_size;
  const char *full_text;
  uint64_t full_text_bytes;
  const char *committed_text;
  uint64_t committed_text_bytes;
  const char *tentative_text;
  uint64_t tentative_text_bytes;
  uint64_t raw_tentative_start_bytes;
} stub_stream_text;

static int revision_counter = 0;
static int fed_samples = 0;

const char *transcribe_version(void) { return "test-stub"; }

const char *transcribe_status_string(int status) {
  return status == 0 ? "ok" : "error";
}

int transcribe_open(const char *path, const void *load_params,
                    const void *session_params, void **out_session) {
  (void)load_params;
  (void)session_params;
  if (path == NULL || strstr(path, "missing") != NULL) {
    *out_session = NULL;
    return 3;
  }
  *out_session = (void *)0x1;
  return 0;
}

void transcribe_session_free(void *session) { (void)session; }

int transcribe_stream_begin(void *session, const void *run_params,
                            const void *stream_params) {
  (void)run_params;
  (void)stream_params;
  if (session == NULL) return 1;
  revision_counter++;
  return 0;
}

int transcribe_stream_feed(void *session, const float *pcm, int n_samples,
                           void *update) {
  (void)update;
  if (session == NULL || pcm == NULL || n_samples <= 0) return 1;
  fed_samples += n_samples;
  revision_counter++;
  return 0;
}

int transcribe_stream_finalize(void *session, void *update) {
  (void)update;
  if (session == NULL) return 1;
  revision_counter++;
  return 0;
}

void transcribe_stream_reset(void *session) { (void)session; }

int transcribe_stream_revision(void *session) {
  if (session == NULL) return 0;
  return revision_counter;
}

int transcribe_stream_get_text(void *session, stub_stream_text *out) {
  static const char text[] = "stub transcript";
  if (session == NULL || out == NULL) return 1;
  out->struct_size = sizeof(stub_stream_text);
  out->full_text = text;
  out->full_text_bytes = sizeof(text) - 1;
  return 0;
}

int transcribe_fed_samples(void) { return fed_samples; }
