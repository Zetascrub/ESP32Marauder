#include <unity.h>
#include "WardriveProbe.h"

void test_directed_probe_parser_and_gate() {
  uint8_t frame[31] = {};
  frame[0] = 0x40;
  frame[10] = 0x02;
  frame[15] = 0x42;
  frame[24] = 0; frame[25] = 5;
  memcpy(frame + 26, "Cafe!", 5);
  WardriveProbeEvent event = {};
  TEST_ASSERT_TRUE(directedWardriveProbe(frame, sizeof(frame), event));
  TEST_ASSERT_EQUAL_STRING_LEN("Cafe!", event.name, 5);
  WardriveProbeQueue queue;
  TEST_ASSERT_TRUE(queue.push(event, 1000));
  TEST_ASSERT_FALSE(queue.push(event, 2000));
  WardriveProbeEvent other = event;
  memcpy(other.name, "Home!", 5);
  TEST_ASSERT_TRUE(queue.push(other, 2000));
  TEST_ASSERT_TRUE(queue.push(event, 11000));
  TEST_ASSERT_TRUE(queue.pop(other));
  TEST_ASSERT_EQUAL_STRING_LEN("Cafe!", other.name, 5);
  frame[25] = 0;
  TEST_ASSERT_FALSE(directedWardriveProbe(frame, sizeof(frame), event));
  frame[25] = 33;
  TEST_ASSERT_FALSE(directedWardriveProbe(frame, sizeof(frame), event));
}

int main() {
  UNITY_BEGIN();
  RUN_TEST(test_directed_probe_parser_and_gate);
  return UNITY_END();
}
