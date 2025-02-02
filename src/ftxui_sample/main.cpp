#include <random>

#include <CLI/CLI.hpp>
#include <spdlog/spdlog.h>
// This file will be generated automatically when cur_you run the CMake
// configuration step. It creates a namespace called `SDL3RT`. You can modify
// the source template at `configured_files/config.hpp.in`.
#include <internal_use_only/config.hpp>

#include "SDL3/SDL.h"

// NOLINTNEXTLINE(bugprone-exception-escape)
int main(int argc, const char **argv)
{
  try {
    CLI::App app{ fmt::format("{} version {}", SDL3RT::cmake::project_name, SDL3RT::cmake::project_version) };

    std::optional<std::string> message;
    app.add_option("-m,--message", message, "A message to print back out");
    bool show_version = false;
    app.add_flag("--version", show_version, "Show version information");

    bool is_turn_based = false;
    auto *turn_based = app.add_flag("--turn_based", is_turn_based);

    bool is_loop_based = false;
    auto *loop_based = app.add_flag("--loop_based", is_loop_based);

    turn_based->excludes(loop_based);
    loop_based->excludes(turn_based);


    CLI11_PARSE(app, argc, argv);

    if (show_version) {
      fmt::print("{}\n", SDL3RT::cmake::project_version);
      return EXIT_SUCCESS;
    }

    [[maybe_unused]] SDL_Window *window = nullptr;
    [[maybe_unused]] SDL_Renderer *renderer = nullptr;
    int result = SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS);
    if (result < 0) {
      spdlog::error("SDL could not initialize! SDL_Error: {}", SDL_GetError());
      return EXIT_FAILURE;
    }
    window = SDL_CreateWindow("SDL3RT", 640, 480, 0);
    if (window == nullptr) {
      spdlog::error("Window could not be created! SDL_Error: {}", SDL_GetError());
      return EXIT_FAILURE;
    }
    renderer = SDL_CreateRenderer(window, nullptr);
    if (renderer == nullptr) {
      spdlog::error("Renderer could not be created! SDL_Error: {}", SDL_GetError());
      return EXIT_FAILURE;
    }

    spdlog::info("SDL3RT is running!");

    SDL_Event event;
    bool quit = false;
    while (!quit) {
      while (SDL_PollEvent(&event) != 0) {
        switch (event.type) {
        case SDL_EVENT_QUIT:
          quit = true;
          spdlog::info("SDL3RT event quit!");
          break;
        default:
          break;
        }
      }
      SDL_SetRenderDrawColor(renderer, 0, 0, 0xff, 0xff);
      SDL_RenderClear(renderer);
      SDL_RenderPresent(renderer);
      SDL_Delay(1);
    }
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    spdlog::info("SDL3RT is shuttin down!");
    return EXIT_SUCCESS;
  } catch (const std::exception &e) {
    spdlog::error("Unhandled exception in main: {}", e.what());
  }
}
