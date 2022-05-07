import subprocess
from datetime import datetime

BUFFER_DURATION = 30 # in days

def get_password_expiry_from_chage(account):
  try:
    chage = subprocess.Popen(('chage', '-l', account), stdout=subprocess.PIPE)
    grep = subprocess.Popen(('grep', 'Password expires'), stdin=chage.stdout, stdout=subprocess.PIPE)
    cut = subprocess.Popen('cut -d : -f2'.split(), stdin=grep.stdout, stdout=subprocess.PIPE)
    output = cut.communicate()[0].strip()
    return output if output != 'never' else None
  except subprocess.CalledProcessError as e:
    return None

def is_going_to_expire(chage_date):
  expiry_date = datetime.strptime(chage_date, '%b %d, %Y')
  today = datetime.now()
  print abs((expiry_date - today).days)
  expiring = abs((expiry_date - today).days) <= BUFFER_DURATION
  return {"expiring": expiring, "in_days": abs((expiry_date - today).days)}

def main():
  # Get a list of accounts from /etc/passwd
  accounts = subprocess.check_output(['cut', '-d:', '-f1', '/etc/passwd']) \
                       .strip() \
                       .split('\n')

  for account in accounts:
    # Get expiry date from chage program
    chage_date = get_password_expiry_from_chage(account)

    # Determine if password is going to expire for account
    if chage_date != None and is_going_to_expire(chage_date)["expiring"]:
      print account + ' is going to expire on ' + str(is_going_to_expire(chage_date)["in_days"]) + ' days'

main()


