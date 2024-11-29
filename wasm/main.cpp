#include <iostream>

#include "wasm/json.hpp"
using json = nlohmann::json;

extern "C" int dataLength();

int main() {
  std::cout << dataLength() << "\n";

  std::puts("done");
  return 0;
}
