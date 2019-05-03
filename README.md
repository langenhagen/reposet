# Reposet
A flexible and simple command to deal with sets of `git` repositories.

![](res/screen-example.gif)


As opposed to working on many `git` repository one after another, `reposet` runs common operations
on a given sets of repositories.
`Reposet` provides convenience commands for the most common `git`-related tasks, like `push` and
`pull`.
`Reposet` also allows to run any command with the repositories's directories set as the working
directory.
`Reposet` can handle several user-defined sets of repositories. It also supports a default set of
repositories.
`Reposet` is written in `bash` and does not require additional dependencies besides `git`.

`Reposet` supports following commands:
- `pull`
- `push`
- `sync` (combined `pull`/`push`)
- `status`
- `list`
- `list-sets`
- `apply` (any given `bash` command or series of commands)

After you set up your first reposet, just call `reposet <command> [<reposet>...]`, to trigger a
command.
See below for further information.
You can also call `reposet <command> --help`.

The project is structured as follows:
```
.
├── example.reposet                 Example reposet definition for reference.
├── README.md                       You are here now.
├── res                             Additional resources.
├── src                             Contains the sources.
│   └── reposet                     The reposet command.
├── setup.sh                        Copies the reposet command into your environment.
├── uninstall.sh                    Removes the reposet command from your environment.
└── util                            Utility scripts.
```


## Prerequisites
`reposet` needs no prerequisites except `git`. It should run on all `Unix`-like systems.


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
Calling `reposet pull my` pulls from the remote branches on the repos defined in a file
`my.reposet`.
Calling `reposet pull my work` pulls from repos defined in the files `my.reposet` and
`work.reposet`.
A `reposet` may contain the same repo specification several times. In this case, a call to `reposet`
will execute the specified action on the repository repeatedly. The same holds when two or more sets
are given to a `reposet` command and repository specifications repeat. Strictly speaking, `reposets`
rather define lists of repos instead of sets.

### Reposet Files
A `reposet` is a `bash` file with the extension `*.reposet` which defines an array named `repos`
whose elements describe a locally available `git` repository.
A `reposet` file must be located in the directory `$HOME/.reposets`.
The name of a `reposet` is equal of the name of the file, without the suffix `.reposet`.
For instance, a `reposet` called "my" would be defined in a file located at
`$HOME/.reposets/my.reposet`.

The form of one element in the array `repos` should be:

`"<local path>:<local default branch>:<remote-pull-repo>:<remote-pull-branch>:<remote-push-repo>:<remote-push-branch>"`

For example, the following array would have valid form:
```bash
repos=(
    "${HOME}/my projects/project1:master:origin:master:origin:master"
    "${HOME}/my projects/project1:dev::origin:staging:origin:staging"
    "${HOME}/my projects/my-gerrit-project:master:origin:master:origin:refs/for/master"
    "${HOME}/dotfiles:master:origin:master:origin:master"
)
```
For a complete example, see the file `example.reposet`.

### Creating a Reposet
An easy way to create a `reposet`, is to copy the `example.reposet` into the directory
`$HOME/.reposets` and modify the copy:
```bash
mkdir -p ~/.reposets
cp example.reposet ~/.reposet/NAME.reposet  # adjust NAME
vim ~/.reposets/NAME.reposet  # adjust NAME
```

Preferrably, `reposets` have simple and short names and start with a letter or a number.
`Reposets` whose names start with a minus (`-`) may be mistaken with command line options.
Well suited names are for example "all", "my" or "work".

#### Exotic reposets
Since a `*.reposet` file is simply a `bash` file that is sourced into the program, it can do all
kinds of things. For example, it can create the array `repos` dynamically on demand. For instance,
a reposet "all.reposet" can aggregate the repos from other reposets. Get creative!

### Using the `reposet` Command
TODO

```
    reposet apply
    reposet list-sets
    reposet sets
    reposet list
    reposet ls
    reposet pull
    reposet down
    reposet push
    reposet up
    reposet status
reposet sync
```


## Similar Software
`reposet` provides a command that is convenient and simple without impairing flexibility.
It comes with minimal dependencies and requires no learning. `Reposet` is agnostic to the location
the `git` repositories it acts on.

There are plenty tools that do the similar work, albeit with different approaches.

### gita
`gita` (https://github.com/nosarthur/gita) can delegate `git` commands/aliases to one set of `git`
repos and show the the `git` status.
`gita` can only handle one set of repositories.
`gita` is written in `Python`.
`reposets` is more flexible due to its capability to handle several sets of repositories.
Furthermore, `reposets` is not limited to the execution of `git` commands on the repositories.

### myrepos
`myrepos` (https://myrepos.branchable.com/) claims to manage your version control repositories.
It also claims support all kinds of version control systems, including `git` and `Darks`.
`myrepo` is highly configurable and can also automate certain tasks.
`reposets` is more lightweight than `myrepos`.

### repo
`repo` (https://source.android.com/setup/develop/repo) unifies `git` repositories and is meant to
aid the `Android` development workflow.
`repo` needs the `git` repositories to lie in the same directory tree.
`repo` is written in `Python`.
`reposets` is more lightweight than `repo` and more flexible, due to `reposets` being agnostic of
the directories the repositories reside in.

### vcstool
`vcstool` (https://github.com/dirk-thomas/vcstool) aims to make work with several repositories
easier.
It can handle repos of the version control the systems `git`, `Mercurial`, `Subversion` and
`Bazaar`.
It is written in `Python`.
`reposets` is more lightweight than `myrepos`.


## Coding
TODO


## Roadmap
At the moment, I am happy with the features `reposet` provides.
I will implement more command line arguments for the commands when the need arises.

Individual repos could get an additional property that forbids pushing, or maybe repo definitions
could accept empty remotes and remote branches for pushing in order to forbid pushing.

I thought of a subcommand to add a given git repository to a given reposet from the command line.

Also, the output of reposet-list could get a more sophisticated way of formatting. At the moment, it
is dependent on a maximume length of the fields it prints. When this length is exceeded, the tabular
output is messed up. That could be improved.


## Contributing
Work on your stuff locally, branch, commit and modify to your heart's content.
If there is anything you can correct, extend or improve, please do so!
Happy coding!


## TODO
- implement `reposet-sync`
- finish help msg for `reposet`
- write `README.md`
    - mention helper function to support uniformity.
    - mention in the coding section that common variables exist and that they are updated indirectly
      via certain helper functions like n_current_repo++ which are meant to be used in an idiomatic way
    - state, that you can combine several reposets but not the default reposet
        - and that it may be wise that th default reposet is a symlink to a named reposet

