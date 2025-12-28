pragma solidity ^0.8;

// create company account, kyc/aml, bbb

function createCompanyAccount ={
company name = $companyName;
first name = $firstName;
last name = $lastName;
headquarters address = $hqAddress;
return companyAccount;}

// create worker account
function createWorkerAccount ={
first name = $firstName;
last name = $lastName;
address = $address;
bank details = $bankingDetails;
pi wallet address = $piAddress;
return workerAccount;
}

// list jobs
function jobsHiring ={
company name = $companyName;
company job title = $jobTitle;
company job description = $jobDescription;
company job salary = $jobSalary;
company job locaton = $jobLocation;
company job contact information = $jobContactInfo;
return jobHiring;

}


// apply for jobs
function applyForJob ={
first name = $firstName;
last name = $lastName;
job experience = $jobExperience;
location = $locaton;
contact information = $contactInformation;
return jobAppliedTo;

}

// message back-forth
function jobBoardChat ={
     (require == workerAccount);
     (require == companyAccount);
// peer2peer chat room

