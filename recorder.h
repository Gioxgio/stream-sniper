/*
 * recorder.h - thread lifecycle for recordings.
 *
 * Owns the runtime state of every channel in a private rec_slot_t[]
 * indexed like the channel array passed to recorder_init(): an atomic
 * busy flag plus the pid / thread / has_thread of that channel's
 * recorder thread. Callers outside this module must treat those
 * fields as opaque and go through the functions below.
 */

#ifndef RECORDER_H
#define RECORDER_H

#include <stdbool.h>
#include <stddef.h>
#include "urlparse.h"

/*
 * Bind the recorder to the channel array main is about to sweep and
 * remember where recordings land. Call once, after config_load() and
 * before any other recorder function. Returns false if the slot array
 * cannot be allocated.
 */
bool recorder_init(const channel_t *chans, size_t n, const char *out_dir);

/* True if this channel already has an active recording thread. */
bool recorder_is_busy(const channel_t *ch);

/*
 * If the channel is idle, mark its slot busy and spawn a recording
 * thread that records stream_url. Takes ownership of stream_url:
 * it is freed on every path - by this function when the thread
 * cannot be started, and by the recording thread itself once
 * yt-dlp has the URL or has failed before using it. Returns
 * true if a thread was started, false otherwise (unknown
 * channel, already busy, or thread creation failed).
 */
bool recorder_start(const channel_t *ch, char *stream_url);

/*
 * Stop everything: SIGTERM all live yt-dlp children, then join every
 * recording thread. Called once at shutdown.
 */
void recorder_shutdown(void);

#endif /* RECORDER_H */
