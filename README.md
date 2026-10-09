### Install instructions
1. Go to FileSystem tab in the right side column in Godot.
2. Select top folder in the hierarchy, right click and open in explorer.
3. Create a subfolder from project root and name it "tools".
4. Paste the files from the New Project Setup in the newly created tools-folder.
5. In Godot's FileSystem tab, expand the tools folder and double-click
project_setup.tscn. Make sure its scene tab is open (the editor should not say
"[empty]").
6. Run the open scene with F6 (Scene > Run Current Scene). Merely selecting the
file in the FileSystem tab does not open it.
Do not use F5 / "Run Project" yet: this setup scene can run without a project
main scene, but the project itself needs one before you can run the game with F5.
7. After the setup finishes successfully, you can delete the copied installer files
from tools: Install instructions.txt, project_setup.gd, project_setup.gd.uid and
project_setup.tscn (plus any installer README copied there).
Keep the tools folder;
the setup script created it for future development tools.
8. Keep the README.md at the
project root.

README included with instructions on what to put where, conventions and how to set things like Input mapping manually.

<img width="288" height="465" alt="image" src="https://github.com/user-attachments/assets/d41062ec-054a-44f4-bf3d-d562145c5154" />
