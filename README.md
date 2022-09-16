## Create a GitHub token

https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token

No special scopes should be necessary.

## Dependencies

* bash
* jq

On Mac OS X, brew can be used to install jq: `brew install jq`

## Usage
My initial use-case for the output CSV is to see PR contributions to a known set of repos for a given team of members.

##### Sample run:
```
./analyze.sh -l sfalknerhorine -t ~/.github-token -r repos -o results.csv
```
* -l = my GitHub login
* -t = file containing my GitHub token
* -r = file containing list of repos, one per line, e.g. "apache/zookeeper"
* -o = output csv file name

Notes:
* The script takes awhile to run, but should avoid rate-limiting via 1-second delay between each query.
* As written, the script (loosely) **targets 2022 only**. (See `$latest` logic.) This is a quick performance optimization for long-running active repos, and should be easy to adjust locally, until more elegant support is added.

##### Once I have the CSV
* Import into Google sheets
* Add new column "Date (fixed)"
  - Formula pattern: `=DATEVALUE(MID($C2,1,10)) + TIMEVALUE(MID($C2,12,8))`
  - This is my solution for converting the text date to a Date object. There's probably a better solution.
* Create filters and pivot tables as desired

##### Example fancy query
* "data" tab = CSV results (including "Date (fixed)" column G)
* Cell A2 = earliest date I'm targeting
* Range A5:A11 = list of team members (GitHub IDs)

This summarizes the # of PRs for each of the team members in my list:
```
=QUERY(data!A1:G, "SELECT B, COUNT(B) WHERE G > date '"&TEXT(DATEVALUE($A$2),"yyyy-mm-dd")&"' AND B MATCHES '("&JOIN("|", $A$5:$A)&")' GROUP BY B ORDER BY COUNT(B) DESC LABEL COUNT(B) 'PRs'", 1)
```

This shows the actual PRs for the team members in my list:
```
=QUERY(data!A1:G, "SELECT A, B, C, D, F WHERE G > date '"&TEXT(DATEVALUE($A$2),"yyyy-mm-dd")&"' AND B MATCHES '("&JOIN("|", $A$5:$A)&")' ORDER BY C DESC", 1)
```

And as always, Pivot tables are fun too!
