#include <iostream>

#include "wasm/json.hpp"
using json = nlohmann::json;

int main(int argc, char **argv) {
  for (int i = 0; i < argc; i++) {
    json data = json::parse(argv[i]);
    std::cerr << data["test1"] << '\n';
  }

  std::puts("done");
  return 0;
}
