# CTF-Scoreboard

### What is this?

This repository is for the scoreboard used to run MITRE capture the flag competitions.

### How to Run Locally

1. Install ruby.
2. In your terminal run `gem install bundle`
3. Run `bundle install`
4. Run `bundle exec rails s`
5. Open the webpage shown in your terminal from the last command in your browser.

### How to Run with Docker

1. Install docker and docker-compose for your platform
2. Clone this project to your local system
3. Create a .env_vars file in the root containing the contents `SECRET_KEY_BASE=<put your secret key here!>`
4. From this directory on your system run `docker-compose up -d`
5. Run `docker-compose run web rake db:create`
6. Run `docker-compose run web rake db:schema:load`
7. Run `docker-compose run web rake db:seed`
8. Login to the scoreboard as email: `root`, password: `ChangePa$$w0rd` and change the password.
9. The scoreboard should now be running at `http://<your-ip>:3000`

### How do I contribute?

1. Fork the repository on github
2. Run `git clone [address]`
3. Make your edits
4. View your edits
5. Run the git add and commit commands. Please make sure your commit messages are descriptive.
6. Run `git push origin master`
7. Submit a pull request
