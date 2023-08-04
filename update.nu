

# Wrapper for cross platform symlinks, this uses soft links on all platforms.
def link [src:string, target:string, --dry, --verbose(-v), --absolute(-a) ] {

	def _log [msg: string] {
		print $"(ansi yellow)($msg)(ansi reset)"
	}

	# safe checks
	let dir = ($src | path type | $in == dir)
	let src_exist = ($src | path exists)

	let target_exist = ($target | path exists)
	let fam = $nu.os-info.family

	if ($verbose) {
		_log $"Family: ($fam) | Source is a directory: ($dir) | Target exist: ($target_exist)"
		_log $"Will symlink ($src | path expand) in ($target | path expand)"
	}
	if $src_exist == false {
		print $"(ansi red_bold)Source does not exists, aborting.(ansi reset)"
		return
	}
	if $target_exist {
		print $"(ansi red_bold)Target exists, aborting.(ansi reset)"
		return
	}

	let src = if $absolute {
		($src | path expand | str replace -sa '\' '/' )
		} else {
			$src
		}
	let target = if $absolute {
		($target | path expand | str replace -sa '\' '/' )
		} else {
			$target
		}
	if $dry {
		print $"Would run:"
	}
	if $nu.os-info.family == windows {
		let src = ($src | str replace -sa '/' '\')
		let target = ($target | str replace -sa '/' '\')
		if $dir {
			if $dry or $verbose {
				print $"mklink /D \"($target)\" \"($src)\""
			}
			if $dry == false {
				mklink /D $target $src
			}
		} else {
			if $dry or $verbose {
				print $"mklink \"($target)\" \"($src)\""
			}
			if $dry == false {
				mklink $"($target)" $"($src)"
			}
		}
	} else  {
		if $dry or $verbose {
			print $"ln -s \"($src)\" \"($target)\""
		}
		if $dry == false {
			ln -s $"($src)" $"($target)"
		}
	}
}


def main [] {
    let root = $env.FILE_PWD
    let models = $"($root)/models"

    cd $root

    let branch_name = (git rev-parse --abbrev-ref HEAD | str trim)

    print $"(ansi yellow_italic)Backing up and removing models symlinks(ansi reset)"

    cd $models

    # find all symlinks
    let links = (ls -la | 
        where not ($it.target | is-empty) | 
        select name target | 
        sort-by name)
		

	if not ($links | is-empty) {
        $links | save -f links.nuon
		# remove them
		open links.nuon | each {|p| rm $p.name }
	}

    cd $root

    print $"(ansi yellow_italic)Checking out to master(ansi reset)"
    git checkout master

    print $"(ansi yellow_italic)Fetching and pulling remote updates(ansi reset)"
    git fetch
    git pull

    print $"(ansi yellow_italic)Back to our branch \(($branch_name)\)(ansi reset)"
    git checkout -

    print $"(ansi yellow_italic)Merging changes(ansi reset)"
    git merge master

    print $"(ansi yellow_italic)Linking back the models(ansi reset)"
    
    cd $models
    # resymlink them
    open links.nuon | each {|p| link -a $p.target $p.name }

    let commit_count = (git rev-list --count $branch_name $"^origin/($branch_name)")


    print $"(ansi green_bold)Update successful \(($commit_count) new commits\)(ansi reset)"
}
