Use firecrawl to extract text from https://en.wikipedia.org/wiki/Snake_(video_game_genre) . We are only interested in the text describing the game, gameplay, visuals, art, and game mechanics. Anything about the history, dates, genre, sequels, later games, name of video games, legacy, references, external links, or wikipedia metadata are not necessary. The goal is to get a rough game idea outline but for now we just want the relevant text from this website.

Read the snake-gameplay-extracted.md file and create a very simple product requirement document based off of that file. The goal is to describe a simple 2D game that will be implemented in godot. It should be 2D. If it's not clear what features should be in the final game work back and forth with me by asking clarifying questions before writing out the new snake-prd.md.

Move the prd to the correct place that taskmaster expects it to be.

(that moved it to .taskmaster/docs/prd.txt)

(At this point i thought the thing it created kinda sucks. Reworking and rerunning the prompt, but commiting this for posterity.)

Read the snake-gameplay-extracted.md file and create a very simple product requirement document based off of that file while also following the .taskmaster\templates\example_prd.txt template. The goal is to describe a simple 2D game that will be implemented in godot. It should be 2D. If it's not clear what features should be in the final game work back and forth with me by asking clarifying questions before writing out the new prd. Save out the prd into .taskmaster/docs/prd.txt.

(then I just directly ran task-master parse or some shit. Then task-master loop --verbose. But godot wasn't on the path so it fucked up. After fixing the compiler error and one time setup it works. Jank AF visuals though.)