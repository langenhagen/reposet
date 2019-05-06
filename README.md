# Reposet
A flexible and simple command to deal with sets of `git` repositories.

![](res/screen-example.gif)


As opposed to working on many `git` repository one after another, `reposet` runs common operations
on given sets of repositories.
`Reposet` provides convenience commands for the most common `git`-related tasks, like `push` and
`pull`.
`Reposet` also allows to run any command with the repositories' directories as the working
directories.
`Reposet` can handle several user-defined sets of repositories. It also supports a default set.
`Reposet` is written in `bash` and does not require additional dependencies besides `git`.

`Reposet` supports following commands:
- `pull`
- `push`
- `sync` (combined `pull`/`push`)
- `status`
- `list`
- `list-sets`
- `apply` (any given `bash` command or series of commands)

After you set up your first reposet, call `reposet <command> [<reposet>...]`, to trigger a command.
See below for further information.
To get help with the commands, you can call `reposet <command> --help`.

The project is structured as follows:
```
.
├── README.md                       You are here now.
├── res                             Additional resources.
│   └── example.reposet             Example reposet definition for reference.
├── src                             Contains the sources.
│   └── reposet                     The reposet command.
├── setup.sh                        Copies the reposet command into your environment.
├── uninstall.sh                    Removes the reposet command from your environment.
└── util                            Utility scripts.
```


## Prerequisites
`reposet` needs no prerequisites except `bash` and `git`. It should run on all `Unix`-like systems.


## Installation
To install `reposet`, clone the `git` repository anywhere onto your system:
```bash
git clone git@github.com:langenhagen/reposet.git
```

Then, execute the script `setup.sh`:
```bash
bash setup.sh
```
This copies the scripts into the directory `/usr/local/bin`.

To verify, run:
```bash
reposet --version
```


## Deinstallation
To uninstall, call:
```bash
bash uninstall.sh
```
This deletes the scripts from the directory `/usr/local/bin`.

You may also delete the `git` repository.


## Usage
Calling the `reposet` command has the general form: `reposet <subcommand> [<reposet>...]`.

For example, calling `reposet pull`, pulls changes from the default remote branches to the default
local branches on all repositories in the default set of repositories.
Calling `reposet pull my` pulls from the remote branches on the repos listed in a file
`$HOME/.reposets/my.reposet` (see below in section **Reposet Files**).
Calling `reposet pull my work` pulls from repos listed in the files `my.reposet` and
`work.reposet`.

### Reposet Files
A reposet is a `bash` file with the extension `*.reposet` that defines an array whose elements
describe an existing `git` repository.
A `reposet` subcommand may source a `*.reposet` file in order to load repository information.
A `*.reposet` file must be located in the directory `$HOME/.reposets`.
The name of a reposet is equal of the name of the file, without the suffix `.reposet`.
For instance, a reposet called "my" would be defined in the file `$HOME/.reposets/my.reposet`.
The special default reposet `.reposet` does not have a name and may be used when calling a `reposet`
subcommand with no reposets specified.

The array inside the `*.reposet`-files that defines which repositories belong to the reposet has to
have the name `repos`.
One element in the array `repos` specifies 6 important attributes of one git repository, each
attribute separated by a colon `:`.
The form of one element that describes a git repository in the array `repos` is:

`"<local-path>:<local-default-branch>:[<remote-pull-repo>]:[<remote-pull-branch>]:[<remote-push-repo>]:[<remote-push-branch>]"`

Specification of remotes and remote branches is optional. If they are missing, push and pull
operations are disabled for the respective repository. Even in this case, the colon-delimeters `:`
are required.

As an example, the following array would have valid form:
```bash
repos=(
    "${HOME}/my projects/project1:master:origin:master:origin:master"
    "${HOME}/my projects/project1:dev::origin:staging:origin:staging"
    "${HOME}/my projects/my-gerrit-project:master:origin:master:origin:refs/for/master"
    "${HOME}/my projects/pull-only-project:master:origin:master::"
    "${HOME}/my projects/local-only-project:master::::"
    "${HOME}/dotfiles:master:origin:master:origin:master"
)
```
For a complete example, review the file `res/example.reposet`.

If a reposet contains the same repo specification several times, a call to `reposet` will execute
the specified action on the repository repeatedly. The same holds when two or more reposets with
overlapping repository specifications are given to a `reposet` command. Strictly speaking, reposets
rather define lists of repos than sets.

### Creating a Reposet
An easy way to create a reposet, is to copy the file `res/example.reposet` into the directory
`$HOME/.reposets` and modify the copy:
```bash
mkdir -p ~/.reposets
cp res/example.reposet ~/.reposet/NAME.reposet  # adjust NAME
vim ~/.reposets/NAME.reposet  # adjust NAME
```
Preferrably, reposets have simple and short names and start with a letter or a number.
Well suited names are for example "all", "my" or "work".
Naming the new reposet file `.reposet` creates the default reposet. This reposet will be used when
calls to the command `reposet` do not specify which reposets are to be used.

#### Exotic reposets
Since a `*.reposet` file is simply a `bash` file that is sourced into the program, it can do all
kinds of things. For example, a reposet file `all.reposet` may aggregate the repos from other
reposets dynamically. Get creative!

### Using the `reposet` Command
Calling the `reposet` command has the general form: `reposet <subcommand> [<reposet>...]`.

The available commands are:
- `reposet apply` - apply a given bash command on all git repositories
- `reposet list-sets` - list all reposets
- `reposet list` - list all git repositories in the given reposets
- `reposet pull` - call `git pull --rebase` on the repos
- `reposet push` - call `git push` on the repos
- `reposet status` - call `git status` on the repos
- `reposet sync` - call `git pull --rebase` and then `git push` on each repo

Calling `reposet <subcommand> --help` provides a usage description for each subcommand.

`reposet` commands take an arbitrary number of reposets (see above in section **Reposet Files**) as
arguments.
If no reposet is given as an argument, the default reposet is used.
If several reposets are given, their items are chained.

The default reposet can not be chained with other reposets.
To circumvent this limitation, create a named reposet that you want to use as default and source
its `*.reposet` file in the default reposet file `.reposet`.
For example, the file `.reposet` could source a named reposet "default":
```bash
source ~/.reposets/default.reposet
```

Some subcommands have synonyms:
- `reposet down` is synonym for `reposet pull`
- `reposet ls` is synonym for `reposet list`
- `reposet sets` is synonym for `reposet list-sets`
- `reposet up` is synonym for `reposet push`


## Similar Software
`reposet` provides a command that is convenient and simple without impairing flexibility.
It comes with minimal dependencies and requires little learning.
`Reposet` is agnostic to the location the `git` repositories it acts on.

There are plenty tools that do a similar job, albeit with different slightly different.

### gita
`gita` (https://github.com/nosarthur/gita) can delegate `git` commands/aliases to one set of `git`
repos and show the `git` status.
`gita` can only handle one set of repositories.
`gita` is written in `Python`.
`reposet` is more flexible due to its capability to handle several sets of repositories.
Also, `reposet` is not limited to the execution of `git` commands on the repositories.

### myrepos
`myrepos` (https://myrepos.branchable.com/) claims to manage your version control repositories.
It also claims support all kinds of version control systems, including `git` and lesser known ones
like `Darks`.
`myrepo` is highly configurable and can also automate certain tasks.
`reposet` is rather lightweight compared to `myrepos`.

### repo
`repo` (https://source.android.com/setup/develop/repo) unifies `git` repositories and is meant to
aid the `Android` development workflow.
`repo` needs the `git` repositories to lie in the same directory tree.
`repo` is written in `Python`.
`reposet` is more lightweight than `repo` and more flexible, due to `reposet` being agnostic to the
paths where the repositories reside in.

### vcstool
`vcstool` (https://github.com/dirk-thomas/vcstool) aims to make work with several repositories
easier.
It can handle repositories of the version control the systems `git`, `Mercurial`, `Subversion` and
`Bazaar`.
It is written in `Python`.
`reposet` is rather lightweight compared to `myrepos`.


## Coding
TODO


## Roadmap
At the moment, I am content with the features that `reposet` provides.
I intend to add more command line arguments for the commands when the need arises.
I already thought of some additions and improvements:

Create a new subcommand `reposet-add [<reposet>] [<path>...] [...]` to add a given git repository to
a given reposet via the command line.

Create a command `reposet init [<path>...]` that finds git-repositories under the pwd or under the
given paths and attempts to create a reposet on the given checked out branches and tracked branches.

Implement command line parameters to optionally add or override paths to the `*.reposet` files/paths
in order to provide flexibility and enable sharing of `*.reposet` files.

Add `bash`-completion, `fish`-completion, and completion for other shells.


## Contributing
Work on your stuff locally, branch, commit and modify to your heart's content.
If there is anything you can extend, fix or improve, please do so!
Happy coding!


## TODO
- write `README.md`
    - mention helper function to support uniformity.
    - mention in the coding section that common variables exist and that they are updated indirectly
      via certain helper functions like `n_current_repo++` which are meant to be used in an
      idiomatic way
    - state, that you can combine several reposets but not the default reposet
        - and that it may be wise that th default reposet is a symlink to a named reposet

