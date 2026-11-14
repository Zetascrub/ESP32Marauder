#pragma once

#include <stddef.h>

inline bool validWombatHost(const char* host, size_t length) {
  if (!host || length == 0 || length > 253) return false;
  size_t label_length = 0;
  for (size_t i = 0; i < length; i++) {
    const char c = host[i];
    const bool alphanumeric = (c >= 'a' && c <= 'z') ||
                              (c >= 'A' && c <= 'Z') ||
                              (c >= '0' && c <= '9');
    if (c == '.') {
      if (label_length == 0 || label_length > 63 || host[i - 1] == '-') return false;
      label_length = 0;
    } else if (alphanumeric || (c == '-' && label_length > 0)) {
      label_length++;
    } else {
      return false;
    }
  }
  return label_length > 0 && label_length <= 63 && host[length - 1] != '-';
}
