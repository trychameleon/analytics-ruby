require 'spec_helper'

module Segment
  class Analytics
    describe Client do
      describe '#initialize' do
        it 'should error if no write_key is supplied' do
          expect { Client.new }.to raise_error(ArgumentError)
        end

        it 'should not error if a write_key is supplied' do
          Client.new :write_key => WRITE_KEY
        end

        it 'should not error if a write_key is supplied as a string' do
          Client.new 'write_key' => WRITE_KEY
        end
      end

      describe '#track' do
        before(:all) do
          @client = Client.new :write_key => WRITE_KEY
          @queue = @client.instance_variable_get :@queue
        end

        it 'should error without an event' do
          expect { @client.track(:user_id => 'user') }.to raise_error(ArgumentError)
        end

        it 'should error without a user_id' do
          expect { @client.track(:event => 'Event') }.to raise_error(ArgumentError)
        end

        it 'should error if properties is not a hash' do
          expect {
            @client.track({
              :user_id => 'user',
              :event => 'Event',
              :properties => [1,2,3]
            })
          }.to raise_error(ArgumentError)
        end

        it 'should use the timestamp given' do
          time = Time.parse("1990-07-16 13:30:00.123 UTC")

          @client.track({
            :event => 'testing the timestamp',
            :user_id => 'joe',
            :timestamp => time
          })

          msg = @queue.pop

          expect(Time.parse(msg[:timestamp])).to be_within(1.second).of(time)
        end

        it 'should not error with the required options' do
          @client.track Queued::TRACK
          @queue.pop
        end

        it 'should not error when given string keys' do
          @client.track Utils.stringify_keys(Queued::TRACK)
          @queue.pop
        end

        it 'should convert time and date traits into iso8601 format' do
          @client.track({
            :user_id => 'user',
            :event => 'Event',
            :properties => {
              :time => Time.utc(2013),
              :time_with_zone =>  Time.zone.parse('2013-01-01'),
              :date_time => DateTime.new(2013,1,1),
              :date => Date.new(2013,1,1),
              :nottime => 'x'
            }
          })
          message = @queue.pop
          expect(message[:properties][:time]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:properties][:time_with_zone]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:properties][:date_time]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:properties][:date]).to eq('2013-01-01')
          expect(message[:properties][:nottime]).to eq('x')
        end
      end


      describe '#identify' do
        before(:all) do
          @client = Client.new :write_key => WRITE_KEY
          @queue = @client.instance_variable_get :@queue
        end

        it 'should error without any user id' do
          expect { @client.identify({}) }.to raise_error(ArgumentError)
        end

        it 'should not error with the required options' do
          @client.identify Queued::IDENTIFY
          @queue.pop
        end

        it 'should not error with the required options as strings' do
          @client.identify Utils.stringify_keys(Queued::IDENTIFY)
          @queue.pop
        end

        it 'should convert time and date traits into iso8601 format' do
          @client.identify({
            :user_id => 'user',
            :traits => {
              :time => Time.utc(2013),
              :time_with_zone =>  Time.zone.parse('2013-01-01'),
              :date_time => DateTime.new(2013,1,1),
              :date => Date.new(2013,1,1),
              :nottime => 'x'
            }
          })
          message = @queue.pop
          expect(message[:traits][:time]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:traits][:time_with_zone]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:traits][:date_time]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:traits][:date]).to eq('2013-01-01')
          expect(message[:traits][:nottime]).to eq('x')
        end
      end

      describe '#alias' do
        before :all do
          @client = Client.new :write_key => WRITE_KEY
        end

        it 'should error without from' do
          expect { @client.alias :user_id => 1234 }.to raise_error(ArgumentError)
        end

        it 'should error without to' do
          expect { @client.alias :previous_id => 1234 }.to raise_error(ArgumentError)
        end

        it 'should not error with the required options' do
          @client.alias ALIAS
        end

        it 'should not error with the required options as strings' do
          @client.alias Utils.stringify_keys(ALIAS)
        end
      end

      describe '#group' do
        before :all do
          @client = Client.new :write_key => WRITE_KEY
          @queue = @client.instance_variable_get :@queue
        end

        after :each do
          @client.flush
        end

        it 'should error without group_id' do
          expect { @client.group :user_id => 'foo' }.to raise_error(ArgumentError)
        end

        it 'should error without user_id' do
          expect { @client.group :group_id => 'foo' }.to raise_error(ArgumentError)
        end

        it 'should not error with the required options' do
          @client.group Queued::GROUP
        end

        it 'should not error with the required options as strings' do
          @client.group Utils.stringify_keys(Queued::GROUP)
        end

        it 'should convert time and date traits into iso8601 format' do
          @client.identify({
            :user_id => 'user',
            :group_id => 'group',
            :traits => {
              :time => Time.utc(2013),
              :time_with_zone =>  Time.zone.parse('2013-01-01'),
              :date_time => DateTime.new(2013,1,1),
              :date => Date.new(2013,1,1),
              :nottime => 'x'
            }
          })
          message = @queue.pop
          expect(message[:traits][:time]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:traits][:time_with_zone]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:traits][:date_time]).to eq('2013-01-01T00:00:00.000Z')
          expect(message[:traits][:date]).to eq('2013-01-01')
          expect(message[:traits][:nottime]).to eq('x')
        end
      end

      describe '#page' do
        before :all do
          @client = Client.new :write_key => WRITE_KEY
        end

        it 'should error without user_id' do
          expect { @client.page :name => 'foo' }.to raise_error(ArgumentError)
        end

        it 'should not error with the required options' do
          @client.page Queued::PAGE
        end

        it 'should not error with the required options as strings' do
          @client.page Utils.stringify_keys(Queued::PAGE)
        end
      end

      describe '#screen' do
        before :all do
          @client = Client.new :write_key => WRITE_KEY
        end

        it 'should error without user_id' do
          expect { @client.screen :name => 'foo' }.to raise_error(ArgumentError)
        end

        it 'should not error with the required options' do
          @client.screen Queued::SCREEN
        end

        it 'should not error with the required options as strings' do
          @client.screen Utils.stringify_keys(Queued::SCREEN)
        end
      end

      describe '#flush' do
        before(:all) do
          @client = Client.new :write_key => WRITE_KEY
        end

        it 'should wait for the queue to finish on a flush' do
          @client.identify Queued::IDENTIFY
          @client.track Queued::TRACK
          @client.flush
          expect(@client.queued_messages).to eq(0)
        end

        it 'should complete when the process forks' do
          @client.identify Queued::IDENTIFY

          Process.fork do
            @client.track Queued::TRACK
            @client.flush
            expect(@client.queued_messages).to eq(0)
          end

          Process.wait
        end unless defined? JRUBY_VERSION
      end

      context 'common' do
        before(:all) do
          @client = Client.new :write_key => WRITE_KEY
          @queue = @client.instance_variable_get :@queue
        end

        [:track, :screen, :page, :group, :identify, :alias].each do |name|
          it "should not convert ids given as fixnums to strings for #{name}" do
            @client.send name, :user_id => 1, :group_id => 2, :previous_id => 3, :anonymous_id => 4, :event => "coco barked", :name => "coco"
            message = @queue.pop(true)
            classes = message.select {|key| %i(userId groupId previousId anonymousId).include?(key) }.values.map(&:class).uniq
            expect(classes).to eq([Fixnum])
          end

          it "should send integrations for #{name}" do
            @client.send name, :integrations => { :All => true, :Salesforce => false }, :user_id => 1, :group_id => 2, :previous_id => 3, :anonymous_id => 4, :event => "coco barked", :name => "coco"
            message = @queue.pop(true)
            expect(message[:integrations][:All]).to eq(true)
            expect(message[:integrations][:Salesforce]).to eq(false)
          end
        end
      end
    end
  end
end
