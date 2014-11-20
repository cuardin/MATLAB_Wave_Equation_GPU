// Copyright 2013-2014 The MathWorks, Inc.
#ifndef UTIL_H_
#define _UTIL_H_

#include <exception>
#include <string>

//A simple exception class.
struct CustomException : std::exception 
{
	std::string errMsg;
	CustomException( std::string arg ) { this->errMsg = arg; }
};

#endif