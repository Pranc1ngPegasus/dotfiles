set -x GOPATH $HOME/go
set PATH $GOPATH/bin $PATH
set PATH $HOME/bin $PATH

set -x GOPRIVATE github.com/Kyash

function branch_list
  set branch_name (
    git branch | fzf-tmux
  )
  string trim $branch_name | xargs git switch
end

bind \cs branch_list

function awsprofile
  set profile (
    grep '\[' ~/.aws/credentials | sed -e 's/\[//' -e 's/\]//' | fzf-tmux
  )
  echo $profile
  set AWS_DEFAULT_PROFILE $profile
  set AWS_PROFILE $profile
end

function aws-log-tail
  # AWS profile
  set awsprofiles "production:development:ic-production:ic-development"
  set awsprofile (
    string split : $awsprofiles | fzf-tmux
  )
  set AWS_DEFAULT_PROFILE $awsprofile
  set AWS_PROFILE $awsprofile
  echo $awsprofile

  # AWS environment
  switch $awsprofile
    case 'production'
      set environments_by_profile "prd:prd-sb"
    case 'development'
      set environments_by_profile "stg:stg-sb"
    case '*'
      exit 1
  end

  set environment (
    string split : $environments_by_profile | fzf-tmux
  )
  echo $environment

  set log_group (
    aws logs --profile $awsprofile --region ap-northeast-1 describe-log-groups | jq -r '.logGroups[].logGroupName' | grep direct | grep $environment | fzf-tmux
  )
  echo $log_group

  if test -n "$TMUX"
    set log_group_array (
      string split / $log_group
    )
    set app_name (
      echo $log_group_array[6]
    )
    tmux set-window-option -g automatic-rename off
    tmux set -g pane-border-format "#P #T"
    printf "\033]2;%s\033\\r:" "$app_name@$environment"
  end

  awslogs get $log_group --profile $awsprofile --region ap-northeast-1 --watch --watch-interval 1 --no-group --no-stream --color always --timestamp --aws-region ap-northeast-1 $argv
end

function bastion-db
  # AWS profile
  set awsprofiles "production:development:ic-production:ic-development"
  set awsprofile (
    string split : $awsprofiles | fzf-tmux
  )
  set AWS_DEFAULT_PROFILE $awsprofile
  set AWS_PROFILE $awsprofile
  echo $awsprofile

  # AWS environment
  switch $awsprofile
    case 'production'
      set environments_by_profile "prd:prd-sb"
    case 'development'
      set environments_by_profile "stg:stg-sb"
    case '*'
      exit 1
  end

  set environment (
    string split : $environments_by_profile | fzf-tmux
  )
  echo $environment

  set service (
    aws --profile $awsprofile --region ap-northeast-1 rds describe-db-clusters | jq -r '.DBClusters[].DBClusterIdentifier' | grep direct | grep -v sb | string replace -ra "direct-$environment-" '' | string replace -ra "\-aurora-mysql" '' | fzf-tmux
  )

  echo $service

  # connect bastion server via ssm-session on new window
  set tmux_session_name "$service@$environment"
  tmux new-window -n $tmux_session_name
  tmux split-window -v
  tmux resize-pane -U 30
  tmux send-keys -t $tmux_session_name.0 "AWS_PROFILE=$awsprofile ssh bastion.$environment.direct -NL 3306:mysql.$service.$environment.direct:3306" C-m
  sleep 3
  tmux send-keys -t $tmux_session_name.1 "mycli -u developer direct_$service" C-m
end
