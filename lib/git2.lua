--[[Module: lib.lib
Wrappers for liblib.
--]]

local require  = _G.require
local tonumber = _G.tonumber
local print    = _G.print
local pcall    = _G.pcall
local ipairs   = _G.ipairs
local t_insert = _G.table.insert
local exit     = _G.os.exit

local log_debug = _G.log_debug
local log_warn  = _G.log_warn
local log_error = _G.log_error

module(...)

local ffi = require 'ffi'
local c   = ffi.C


ffi.cdef[[
size_t strlen(const char *s);

typedef unsigned long long git_time_t;
typedef struct git_time {
        git_time_t time; /** time in seconds from epoch */
        int offset;  /** timezone offset, in minutes */
} git_time;

typedef struct git_repository git_repository;
typedef struct git_revwalk git_revwalk;
typedef struct git_commit git_commit;
typedef struct git_object git_object;
typedef struct git_reference git_reference;
typedef struct git_tree git_tree;
typedef struct git_tree_entry git_tree_entry;
typedef struct git_signature {
        char *name;     /** full name of the author */
        char *email;    /** email of the author */
        git_time when;  /** time when the action happened */
} git_signature;
typedef long long git_off_t;
typedef int git_otype;
typedef int git_error;
typedef int git_status_t;

int git_repository_open(git_repository **repository, const char *path);
void git_repository_free(git_repository *repo);

/* oid.h */
typedef struct _git_oid git_oid;
struct _git_oid {
        /** raw binary formatted id */
        unsigned char id[20];
};
void git_oid_fmt(char *str, const git_oid *oid);
int git_oid_iszero(const git_oid *a);

/* error.h */
const git_error * giterr_last(void);
void giterr_clear(void);

/* object.h */
int git_object_lookup(git_object **object_out, git_repository *repo, const git_oid *id, git_otype type);
void git_object_free(git_object *object);

/* revwalk.h */
int git_revwalk_new(git_revwalk **walker, git_repository *repo);
int git_revwalk_push(git_revwalk *walk, const git_oid *oid);
void git_revwalk_sorting(git_revwalk *walk, unsigned int sort_mode);
int git_revwalk_next(git_oid *oid, git_revwalk *walk);
void git_revwalk_free(git_revwalk *walk);

/* ref.h */
int git_reference_resolve(git_reference **resolved_ref, git_reference *ref);
int git_reference_lookup(git_reference **reference_out, git_repository *repo, const char *name);
void git_reference_free(git_reference *ref);
const git_oid * git_reference_oid(git_reference *ref);

/* commit.h */
const git_signature * git_commit_author(git_commit *commit);
const git_signature * git_commit_committer(git_commit *commit);
const char * git_commit_message(git_commit *commit);
int git_commit_tree(git_tree **tree_out, git_commit *commit);
unsigned int git_commit_parentcount(git_commit *commit);
const git_oid * git_commit_parent_oid(git_commit *commit, unsigned int n);
git_oid * git_commit_id(git_commit *commit);
int git_commit_parent(git_commit **parent, git_commit *commit, unsigned int n);
git_time_t git_commit_time(git_commit *commit);

/* tree.h */
typedef struct {
    unsigned int old_attr;
    unsigned int new_attr;
    git_oid old_oid;
    git_oid new_oid;
    git_status_t status;
    const char *path;
} git_tree_diff_data;

typedef int (*git_tree_diff_cb)(const git_tree_diff_data *ptr, void *data);

int git_tree_lookup(git_tree **tree, git_repository *repo, const git_oid *id);
const git_tree_entry * git_tree_entry_byindex(git_tree *tree, unsigned int idx);
int git_tree_diff(git_tree *old, git_tree *newer, git_tree_diff_cb cb, void *data);
int git_tree_get_subtree(git_tree **subtree, git_tree *root, const char *subtree_path);
const git_oid * git_tree_entry_id(const git_tree_entry *entry);
const char * git_tree_entry_name(const git_tree_entry *entry);
int git_oid_cmp(const git_oid *a, const git_oid *b);

/* common.h */
typedef struct {
        char **strings;
        size_t count;
} git_strarray;

/* iterator.h */
typedef int git_iterator_type_t;

/* git_pool.h */
typedef struct git_pool_page git_pool_page;
typedef struct {
        git_pool_page *open; /* pages with space left */
        git_pool_page *full; /* pages with no space left */
        void *free_list;     /* optional: list of freed blocks */
        uint32_t item_size;  /* size of single alloc unit in bytes */
        uint32_t page_size;  /* size of page in bytes */
        uint32_t items;
        unsigned has_string_alloc : 1; /* was the strdup function used */
        unsigned has_multi_item_alloc : 1; /* was items ever > 1 in malloc */
        unsigned has_large_page_alloc : 1; /* are any pages > page_size */
} git_pool;

/* vector.h */
typedef int (*git_vector_cmp)(const void *, const void *);
typedef struct git_vector {
        unsigned int _alloc_size;
        git_vector_cmp _cmp;
        void **contents;
        unsigned int length;
        int sorted;
} git_vector;

/* diff.h */
typedef struct {
    uint32_t flags;             /**< defaults to GIT_DIFF_NORMAL */
    uint16_t context_lines;     /**< defaults to 3 */
    uint16_t interhunk_lines;   /**< defaults to 3 */
    char *old_prefix;           /**< defaults to "a" */
    char *new_prefix;           /**< defaults to "b" */
    git_strarray pathspec;      /**< defaults to show all paths */
} git_diff_options;
 
typedef struct git_diff_list {
    git_repository   *repo;
    git_diff_options opts;
    git_vector       pathspec;
    git_vector       deltas;    /* vector of git_diff_file_delta */
    git_pool pool;
    git_iterator_type_t old_src;
    git_iterator_type_t new_src;
    uint32_t diffcaps;
} git_diff_list;

typedef int git_delta_t;
typedef struct {
    git_oid oid;
    char *path;
    uint16_t mode;
    git_off_t size;
    unsigned int flags;
} git_diff_file;

typedef struct {
    git_diff_file old_file;
    git_diff_file new_file;
    git_delta_t   status;
    unsigned int  similarity; /**< for RENAMED and COPIED, value 0-100 */
    int           binary;
} git_diff_delta;

/**
 * When iterating over a diff, callback that will be made per file.
 */
typedef int (*git_diff_file_fn)(
    void *cb_data,
    git_diff_delta *delta,
    float progress);

/**
 * Structure describing a hunk of a diff.
 */
typedef struct {
    int old_start;
    int old_lines;
    int new_start;
    int new_lines;
} git_diff_range;

/**
 * When iterating over a diff, callback that will be made per hunk.
 */
typedef int (*git_diff_hunk_fn)(
    void *cb_data,
    git_diff_delta *delta,
    git_diff_range *range,
    const char *header,
    size_t header_len);
    
typedef int (*git_diff_data_fn)(
    void *cb_data,
    git_diff_delta *delta,
    git_diff_range *range,
    char line_origin, /**< GIT_DIFF_LINE_... value from above */
    const char *content,
    size_t content_len);
    
int git_diff_foreach(
    git_diff_list *diff,
    void *cb_data,
    git_diff_file_fn file_cb,
    git_diff_hunk_fn hunk_cb,
    git_diff_data_fn line_cb);
    
void git_diff_list_free(git_diff_list *diff);
int git_diff_tree_to_tree(
    git_repository *repo,
    const git_diff_options *opts, /**< can be NULL for defaults */
    git_tree *old_tree,
    git_tree *new_tree,
    git_diff_list **diff);
]]

local found, ret = pcall(ffi.load, 'git2')
if not found then
    log_error('Failed to load libgit2, verify library is installed and in your LD_LOAD_PATH: %s', ret) 

    exit(64)
end

local lib = ret

local GIT_OBJ__EXT1     = 0
local GIT_OBJ_COMMIT    = 1
local GIT_OBJ_TREE      = 2
local GIT_OBJ_BLOB      = 3
local GIT_OBJ_TAG       = 4
local GIT_OBJ__EXT2     = 5
local GIT_OBJ_OFS_DELTA = 6
local GIT_OBJ_REF_DELTA = 7

GIT_SORT_NONE        = 0
GIT_SORT_TOPOLOGICAL = 1
GIT_SORT_TIME        = 2
GIT_SORT_REVERSE     = 4

function last_error()
    return tonumber(lib.giterr_last()[1])
end

--[[Function: repository_open
Get a repo on a repository.

Parameters:
    path - (string) to repository

Returns:
    repo or nil (on error)
--]]
function repository_open(path)
    local out = ffi.new('git_repository*[1]')
    local err = lib.git_repository_open(out, path)
    if err < 0 then
        log_error('%s: Failed opening repository %q: %s', 'git2', path, err)
        
        return nil
    end

    return ffi.gc(out[0], lib.git_repository_free)
end

--[[Function: revwalk_new

Parameters:
    repo - to walk over.
--]]
function revwalk_new(repo, sort, oid)
    local out = ffi.new('git_revwalk*[1]');
    local err = lib.git_revwalk_new(out , repo)
    if err < 0 then
        log_error('%s: Failed instantiating new revwalker: %s', 'git2', err)
        
        return nil
    end
    
    if oid then
        lib.git_revwalk_push(out[0], oid)
    end
    
    if sort then
        lib.git_revwalk_sorting(out[0], sort)
    end

    return ffi.gc(out[0], lib.git_revwalk_free)
end

--[[Function: revwalk_next
Write the next oid in the revision tree to oid.
--]]
function revwalk_next(oid, revwalk)
    return lib.git_revwalk_next(oid, revwalk)
end

--[[Function: git_commit_free
Replacement for the inlined function, git_commit_free.

Parameters:
    commit - to free.
--]]
local function git_commit_free(commit)
    lib.git_object_free(ffi.cast('git_object *', commit))
end

--[[Function: commit_lookup
Replacement for the inlined function, git_commit_lookup.

Resolves and oid to a commit.

Parameters:
    oid  - to resolve to commit.
    repo - objects are located in.
    
Returns:
    commit or nil if error occurred.
--]]
function commit_lookup(repo, oid)
    local commit = ffi.new('git_object*[1]')
    
    local err = lib.git_object_lookup(commit, repo, oid, GIT_OBJ_COMMIT)
    if err < 0 then
        log_error('%s: Failed to resolve oid to commit: %s', 'git2', err)
        
        return nil
    end
    
    return ffi.gc(ffi.cast('git_commit*', commit[0]), git_commit_free)
end

function commit_parentcount(commit)
    return tonumber(lib.git_commit_parentcount(commit))
end

function commit_parent_oid(commit, idx)
    return lib.git_commit_parent_oid(commit, idx);
end

function commit_parent(commit, idx)
    local parent = ffi.new('git_commit*[1]')
    
    local err = lib.git_commit_parent(parent, commit, idx)
    if err < 0 then
        log_error('%s: Failed to retrieve parent commit: %s', 'git2', err)
        
        return nil
    end
    
    return ffi.gc(parent[0], git_commit_free)
end

--[[Function: oid_commit_info
Get relevant information about a commit and insert it into a lua table, 
converting to lua datatypes where necessary.

Parameters:
    commit - to retrieve metadata from.

Returns:
    table with keys
        author          - authors name from sig.
        author_email    - authors email from sig.
        author_time     - the time the commit was authored (unix timestamp).
        committer       - committers name from sig.
        committer_email - committers email from sig.
        committer_time  - the time the commit was committed.
        time            - commit time (should be the same as committer_time?)
        message         - message associated with the commit.
--]]
function commit_info(commit)
    local sig_author = lib.git_commit_author(commit)
    if sig_author == nil then
        log_error('%s: Couldnt get commit author: %s', 'git2', last_error())
        
        return nil
    end
    
    local sig_committer = lib.git_commit_committer(commit)
    if sig_committer == nil then
        log_error('%s: Couldnt get committer: %s', 'git2', last_error())
        
        return nil
    end
    
    local when = lib.git_commit_time(commit)
    if when == 0 then
        log_error('%s: Couldnt get commit time: %s', 'git2', last_error())
        
        return nil
    end   
    
    local message = lib.git_commit_message(commit)
    if message == nil then
        log_error('%s: Couldnt get commit message: %s', 'git2', last_error())
        
        return nil
    end
    
    return {
        author          = ffi.string(sig_author.name),
        author_email    = ffi.string(sig_author.email),
        author_time     = tonumber(sig_author.when.time),
        
        committer       = ffi.string(sig_committer.name),
        committer_email = ffi.string(sig_committer.email),
        committer_time  = tonumber(sig_committer.when.time),
        
        time            = tonumber(when),
        
        message         = ffi.string(message),
    }
end

--[[Function: oid_hash
Convert binary hash to hex.

Parameters:
    oid - to convert.
    
Returns:
    hex string.

--]]
local oid_hash_buff = ffi.new('char[41]')
function oid_hash(oid)
    lib.git_oid_fmt(oid_hash_buff, oid)
    
    return ffi.string(oid_hash_buff, 40)
end

--[[Function: reference_resolve
Recursively peel back layers of references, returning the OID a ref refers to.

Useful for finding the heads of branches etc...

Parameters:
    repo - to search for the reference in.
    name - of the reference.
    
Returns:
    nil - on error.
    git_oid - on success.
--]]
function reference_resolve(repo, name)
    local git_reference = ffi.new('git_reference*[1]')
    
    local err = lib.git_reference_lookup(git_reference, repo, name) 
    if err < 0 then
        log_warn('%s: Failed to find reference %q: %s', 'git2', name, err)
        
        return nil
    end
    
    local git_reference_resolve = ffi.new('git_reference*[1]')
    local err = lib.git_reference_resolve(git_reference_resolve, git_reference[0]) 
    lib.git_reference_free(git_reference[0])
    
    if err < 0 then
        log_warn('%s: Failed to find reference %q: %s', 'git2', name, err) 
        
        return nil
    end
    
    return ffi.gc(git_reference_resolve[0], lib.git_reference_free)
end

--[[Function: oid_splice
Take the first 10 bytes of oid_a, and the last 10 bytes of oid_b and write, 
them into a new oid object.

This object is not useful in the context of the git repo, but does give each 
file a unique commit/path id.

Parameters:
    oid_a - first oid.
    oid_b - second oid.
    
Return:

--]]
function oid_splice(oid_a, oid_b)
    local out = ffi.new('git_oid[1]')
    
    ffi.copy(out[0].id, oid_a.id, 10)
    ffi.copy(out[0].id + 10, oid_b.id + 10, 10)
    
    return out
end

--[[Function: reference_oid
Return the object id associated with a reference.
--]]
function reference_oid(reference)
    local oid = lib.git_reference_oid(reference)
    if oid == nil then
        log_error('%s: Couldnt resolve ref to oid: %s', 'git2', last_error())
        
        return nil
    end
    
    return ffi.cast('git_oid*', oid)
end

--[[Function: oid_equal
Tests quality between two oids
--]]
function oid_equal(oid1, oid2)
    return lib.git_oid_cmp(oid1, oid2) == 0
end

local function git_tree_free(tree)
    lib.git_object_free(ffi.cast('git_object *', tree))
end

function tree_lookup(repo, oid)
    local tree = ffi.new('git_object*[1]')
    
    local err = lib.git_object_lookup(tree, repo, oid, GIT_OBJ_TREE)
    if err < 0 then
        log_error('%s: Failed to resolve oid to tree: %s', 'git2', err)
        
        return nil
    end
    
    return ffi.gc(ffi.cast('git_tree*', tree[0]), git_tree_free)
end

function commit_tree(commit)
    local tree = ffi.new('git_tree*[1]')
    
    local err = lib.git_commit_tree(tree, commit)
    if err < 0 then
        log_error('%s: Failed to resolve commit to tree: %s', 'git2', err)
        
        return nil
    end
    
    return ffi.gc(tree[0], git_tree_free)
end

function commit_filelist(repo, commit)
    local difflist = ffi.new('git_diff_list*[1]')
    local out = {}
    
    local new_tree = commit_tree(commit)
    if not new_tree then
        return nil
    end
    
    local count = commit_parentcount(commit)
    
    if count > 0 then
        for i = 0, count - 1 do
            local parent = commit_parent(commit, i)
            if not parent then
                return nil
            end
            
            local commit_oid = lib.git_commit_id(parent)
            
            local old_tree = commit_tree(parent)
            lib.git_diff_tree_to_tree(repo, nil, old_tree, new_tree, difflist)
            
            lib.git_diff_foreach(difflist[0], nil, 
                function(data, git_diff_data, progress)
                    t_insert(out, {
                        path = ffi.string(git_diff_data.new_file.path),
                        hash = oid_hash(oid_splice(commit_oid, git_diff_data.new_file.oid))
                    })
                    
                    return 0
                end,
                nil, nil)
                
            lib.git_diff_list_free(difflist[0])
        end
        
    -- Handles the corner case where this is the first commit in the repo...
    else
        local commit_oid = lib.git_commit_id(commit)
        
        while true do
            local entry = lib.git_tree_entry_byindex(new_tree, count)
            if entry == nil then
                break
            end
            
            t_insert(out, {
                path = ffi.string(lib.git_tree_entry_name(entry)),
                hash = oid_hash(oid_splice(commit_oid, lib.git_tree_entry_id(entry)))
            })
            
            count = count + 1
        end
    end
    
    return out
end