#!/bin/bash

app_uri=$1
item_name='build a todo app'

### helpers

make_todo_item () {
    todo_item="<li class=\"todo\">
          <span class=\"item-name\">$1</span>
          <form method=\"post\" action=\"/done\">
            <input type=\"hidden\" name=\"item\" value=\"stuff\">
            <input class=\"complete\" type=\"submit\" value=\"Mark done '$1'\">
          </form>
          <form method=\"post\" action=\"/delete\">
            <input type=\"hidden\" name=\"item\" value=\"stuff\">
            <input class=\"delete\" type=\"submit\" value=\"Delete '$1'\">
          </form>
        </li>"
}

curl_post_options='-L -H "Content-Type: application/x-www-form-urlencoded" -s'

### Get the page test

get_test () {
    page="$(curl -s -XGET $app_uri | hxnormalize -x)"
    expected_content="$(cat golden_master.html | hxnormalize -x)"
    diff_result=$(diff <(echo "$expected_content") <(echo "$page"))
    exit=$?

    printf "\tGET test... "
    if [[ $exit -ne 0 ]]; then
        global_failures=true
        printf "FAILED\n"
        printf "DIFF:\n"
        printf "$diff_result\n"
    else
        printf "PASSED\n"
    fi
}

### New todo test
new_todo_test () {
    page=$(curl $curl_post_options -d "item=$item_name" $app_uri)
    make_todo_item "$item_name"
    expected_content=$todo_item

    printf "\tNew todo test..."
    if ! grep -q "$(tr -s '\t ' <<<$expected_content )" <<< "$(tr -s '\t ' <<<$page)"; then
        global_failures=true
        printf "FAILED\n"
        printf "Expected $page\n"
        printf "to contain $expected_content\n"
    else
        printf "PASSED\n"
    fi
}

### Complete todo test
complete_todo_test () {
    page=$(curl $curl_post_options -d "item=$item_name" "$app_uri/done")
    expected_content="<s>$item_name</s>"

    printf "\tComplete todo test... "
    if ! grep -q $expected_content <<< $page; then
        global_failures=true
        printf "FAILED\n"
        printf "Expected $page\n"
        printf "to contain $expected_content\n"
    else
        printf "PASSED\n"
    fi
}

### Delete todo test
delete_todo_test () {
    page=$(curl $curl_post_options -d "item=$item_name" "$app_uri/delete")
    unexpected_content=$item_name

    printf "\tDelete todo test... "
    if grep -q "$unexpected_content" <<< "$page"; then
        global_failures=true
        printf "FAILED\n"
        printf "Expected $page\n"
        printf "not to contain $unexpected_content\n"
    else
        printf "PASSED\n"
    fi
}

### RESULTS

printf "\nRESULTS\n"
get_test
#new_todo_test
#complete_todo_test
#delete_todo_test

if [[ $global_failures = true ]]; then exit 1; fi
