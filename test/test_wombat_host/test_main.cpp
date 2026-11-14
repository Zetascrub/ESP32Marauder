#include <unity.h>

#include "WombatHost.h"

void setUp(void) {}
void tearDown(void) {}

void test_accepts_dns_host(void) {
  TEST_ASSERT_TRUE(validWombatHost("wombat.example.org", 18));
  TEST_ASSERT_TRUE(validWombatHost("my-wombat.example.org", 21));
}

void test_rejects_invalid_or_injectable_host(void) {
  TEST_ASSERT_FALSE(validWombatHost("", 0));
  TEST_ASSERT_FALSE(validWombatHost("https://example.org", 19));
  TEST_ASSERT_FALSE(validWombatHost("example.org:443", 15));
  TEST_ASSERT_FALSE(validWombatHost("example.org\r\nX:evil", 19));
  TEST_ASSERT_FALSE(validWombatHost("bad..host", 9));
  TEST_ASSERT_FALSE(validWombatHost("-bad.host", 9));
  TEST_ASSERT_FALSE(validWombatHost("bad-.host", 9));
}

int main(int, char**) {
  UNITY_BEGIN();
  RUN_TEST(test_accepts_dns_host);
  RUN_TEST(test_rejects_invalid_or_injectable_host);
  return UNITY_END();
}
