// create college account, kyc/aml, bbb

function createCollegeAccount ={
college name = $collegeName;
first name = $firstName;
last name = $lastName;
college address = $collegeAddress; 
return collegeAccount;}



// create collegeCoach account, kyc/aml, bbb

function createCollegeCoachAccount ={
college coach for = $collegeName;
first name = $firstName;
last name = $lastName;
college coach for address = $collegeAddress; 
return collegeCoachAccount;}

// create studentAthlete account, kyc/aml, bbb

function createStudentAccount ={
first name = $firstName;
last name = $lastName;
sport playing = $sportPlaying;
sports position = $sportsPosition;
gpa on 4.0 = $gpa;
major = $major;
return studentAthleteAccount;}

// create student account, kyc/aml, bbb

function createStudentAccount ={
first name = $firstName;
last name = $lastName;
gpa on 4.0 = $gpa;
extracurricular activies = $extraActivities;
major = $major;
return studentAccount;  }







// find student-aid & scholarships

function findStudentAid ={
// aggregation of student aid sites 

     (require == studentAccount);
     (require == studentAthleteAccount);

[1. https://studentaid.gov/],
[2. https://www.fastweb.com/],
[3. https://goingmerry.com/],
[4. https://scholarshipowl.com/scholarships/matches],
[5. https://www.smartscholarship.org/smart/en],
[6. https://www.niche.com/colleges/scholarships/],
[7. https://www.collegescholarships.org/financial-aid/],
[8. https://www.salliemae.com/scholarships/search/],
[9. https://www.salliemae.com/scholarships/search/],
[10. https://www.questbridge.org/]   ;


}

_____________________

contingency: 30% allocated to $CJ3Reserve as $USDC, 70% to sdk/api user;
subscription fee: $25/ a month OR +5% allocated to the owner address;
amount $CJ3 to stake to deploy to mainnet: $100/ per contract using in sdk/api (allocate to $CJ3Reserves as $XLM)
