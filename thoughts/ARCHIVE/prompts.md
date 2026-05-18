Use firecrawl to extract text from https://en.wikipedia.org/wiki/Snake_(video_game_genre) . We are only interested in the text describing the game, gameplay, visuals, art, and game mechanics. Anything about the history, dates, genre, sequels, later games, name of video games, legacy, references, external links, or wikipedia metadata are not necessary. The goal is to get a rough game idea outline but for now we just want the relevant text from this website.

Read the snake-gameplay-extracted.md file and create a very simple product requirement document based off of that file. The goal is to describe a simple 2D game that will be implemented in godot. It should be 2D. If it's not clear what features should be in the final game work back and forth with me by asking clarifying questions before writing out the new snake-prd.md.

Move the prd to the correct place that taskmaster expects it to be.

(that moved it to .taskmaster/docs/prd.txt)

(At this point i thought the thing it created kinda sucks. Reworking and rerunning the prompt, but commiting this for posterity.)

Read the snake-gameplay-extracted.md file and create a very simple product requirement document based off of that file while also following the .taskmaster\templates\example_prd.txt template. The goal is to describe a simple 2D game that will be implemented in godot. It should be 2D. If it's not clear what features should be in the final game work back and forth with me by asking clarifying questions before writing out the new prd. Save out the prd into .taskmaster/docs/prd.txt.

(then I just directly ran task-master parse or some shit. Then task-master loop --verbose. But godot wasn't on the path so it fucked up. After fixing the compiler error and one time setup it works. Jank AF visuals though. Looking at the task-master source code, I'm not that happy with how it splits up the tasks. It seems to just yolo guess 10 every time which the LLM follows. Going to have to make changes to task-master.)

(trying again 5/16/2026 6:38PM)

Read the .firecrawl/snake-gameplay-extracted.md file and create a very simple product requirement document based off of that file into .taskmaster/docs/prd.txt. The goal is to describe a simple 2D game that will be implemented in godot. It should be 2D. If the feature or task requires art split the task into code-implementation-task and a art-implementation-task. For art-implementation-tasks use claude + pixellab mcp and generate the necessary assets that will be used by the code-implementation-task. If it's not clear what features should be in the final game work back and forth with me by asking clarifying questions before writing out the prd.

(It edited the readme reeee. Make sure to primarily edit the godot project C:\GameDev\SnakeGodotTaskmaster\snaketaskmaster . Do not edit any readmes.)

Read the .firecrawl/snake-gameplay-extracted.md file and create a very simple product requirement document based off of that file into .taskmaster/docs/prd.txt. The goal is to describe a simple 2D game that will be implemented in godot. It should be 2D. If the feature or task requires art split the task into code-implementation-task, art-implementation-task, audio-implementation-task. For art-implementation-tasks find the appropriate art asset in source/sprites. For audio-implementation-task find the appropriate audio asset in source/audio. If it's not clear what features should be in the final game work back and forth with me by asking clarifying questions before writing out the prd.