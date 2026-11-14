#pragma once

#include <stddef.h>
#include <stdint.h>
#include <string.h>

struct WardriveProbeEvent {
  uint8_t mac[6];
  uint8_t name[32];
  uint8_t name_length;
  uint8_t channel;
  int8_t rssi;
};

// Ignore broadcast probes and malformed names before they reach the CSV importer.
inline bool directedWardriveProbe(const uint8_t* frame, size_t length,
                                  WardriveProbeEvent& event) {
  if (!frame || length < 26 || frame[0] != 0x40 || (frame[10] & 1)) return false;
  for (size_t at = 24; at + 2 <= length;) {
    const uint8_t kind = frame[at++];
    const uint8_t size = frame[at++];
    if (at + size > length) return false;
    if (kind == 0) {
      if (!size || size > sizeof(event.name)) return false;
      for (size_t i = at; i < at + size;) {
        const uint8_t ch = frame[i++];
        if (ch < 0x20 || ch == 0x7f) return false;
        if (ch < 0x80) continue;
        const size_t extra = ch >= 0xc2 && ch <= 0xdf ? 1 :
                             ch >= 0xe0 && ch <= 0xef ? 2 :
                             ch >= 0xf0 && ch <= 0xf4 ? 3 : 0;
        if (!extra || i + extra > at + size) return false;
        const uint8_t next = frame[i];
        if ((ch == 0xe0 && next < 0xa0) || (ch == 0xed && next >= 0xa0) ||
            (ch == 0xf0 && next < 0x90) || (ch == 0xf4 && next >= 0x90)) return false;
        for (size_t j = 0; j < extra; j++)
          if ((frame[i++] & 0xc0) != 0x80) return false;
      }
      memcpy(event.mac, frame + 10, 6);
      memcpy(event.name, frame + at, size);
      event.name_length = size;
      return true;
    }
    at += size;
  }
  return false;
}

class WardriveProbeQueue {
 public:
  void reset() { memset(this, 0, sizeof(*this)); }

  bool push(const WardriveProbeEvent& event, uint32_t now) {
    const uint8_t next = (head + 1) % 32;
    if (next == tail) { dropped_count++; return false; }
    for (Seen& item : seen) {
      if (item.name_length == event.name_length &&
          memcmp(item.mac, event.mac, 6) == 0 &&
          memcmp(item.name, event.name, event.name_length) == 0) {
        if (now - item.last_seen < 10000) return false;
        item.last_seen = now;
        entries[head] = event;
        head = next;
        return true;
      }
    }
    Seen& item = seen[seen_cursor++ % 64];
    memcpy(item.mac, event.mac, 6);
    memcpy(item.name, event.name, event.name_length);
    item.name_length = event.name_length;
    item.last_seen = now;
    entries[head] = event;
    head = next;
    return true;
  }

  bool pop(WardriveProbeEvent& event) {
    if (tail == head) return false;
    event = entries[tail];
    tail = (tail + 1) % 32;
    return true;
  }

  uint32_t dropped() const { return dropped_count; }

 private:
  struct Seen {
    uint8_t mac[6];
    uint8_t name[32];
    uint8_t name_length;
    uint32_t last_seen;
  };
  Seen seen[64] = {};
  WardriveProbeEvent entries[32] = {};
  uint8_t head = 0;
  uint8_t tail = 0;
  uint8_t seen_cursor = 0;
  uint32_t dropped_count = 0;
};
